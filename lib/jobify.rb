# frozen_string_literal: true

require_relative "jobify/version"

require "active_support"
require "active_job"
require "fileutils"
require "active_support/core_ext/benchmark"

class MissingArgument < ArgumentError; end

class MissingKeywordArgument < ArgumentError; end

# Include to allow running any method as a background job automatically
module Jobify
  extend ActiveSupport::Concern

  included do
    @jobified_methods = {
      instance: {},
      singleton: {}
    }

    def self.jobify(method_name, job_method_name: "perform_#{method_name}_later")
      raise "method name cannot be blank" if method_name.blank?

      method_name = method_name.to_s

      if method_defined?(method_name) && !@jobified_methods[:instance][method_name]
        # Instance method
        params = instance_method(method_name).parameters
        _define_job_class(method_name, job_method_name, params, false)
        @jobified_methods[:instance][method_name] = true
      elsif respond_to?(method_name) && !@jobified_methods[:singleton][method_name]
        # Singleton method (Class method)
        params = method(method_name).parameters
        _define_job_class(method_name, job_method_name, params, true)
        @jobified_methods[:singleton][method_name] = true
      end
    end

    def self._define_job_class(method_name, job_method_name, params, singleton_method)
      job_class_name = singleton_method ? "JobifySingletonMethod_#{method_name}_Job" : "JobifyInstanceMethod_#{method_name}_Job"
      parent_class = defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base
      job_class    = Class.new(parent_class)
      caller_class = self
      const_set(job_class_name, job_class)

      # Define perform method on job class
      if singleton_method
        singleton__define_job_perform_method(job_class, caller_class, method_name)
        singleton__define_job_enqueue_method(job_class, job_method_name, params)
      else
        instance__define_job_perform_method(job_class, caller_class, method_name)
        instance__define_job_enqueue_method(job_class, job_method_name, params)
      end
    end

    def self.singleton__define_job_perform_method(job_class, caller_class, method_name)
      job_class.define_method(:perform) do |*args, **kw_args|
        if kw_args.empty?
          caller_class.public_send(method_name, *args)
        else
          caller_class.public_send(method_name, *args, **kw_args)
        end
      end
    end

    def self.singleton__define_job_enqueue_method(job_class, job_method_name, params)
      define_singleton_method(job_method_name) do |*args, **kw_args|
        req_args    = params.filter_map { _1[0] == :req ? _1[1] : nil }
        req_kw_args = params.filter_map { _1[0] == :keyreq ? _1[1] : nil }

        ensure_required_kw_args_present!(req_kw_args, kw_args)
        ensure_all_args_present!(req_args, args)

        if kw_args.empty?
          job_class.perform_later(*args)
        else
          job_class.perform_later(*args, **kw_args)
        end
      end
    end

    def self.instance__define_job_perform_method(job_class, caller_class, method_name)
      job_class.define_method(:perform) do |*args, **kw_args|
        id = kw_args.delete(:__jobify__record_id)
        raise "Something has gone wrong. Record id is required" unless id

        record = caller_class.find(id)
        record.public_send(method_name, *args, **kw_args)
      end
    end

    def self.instance__define_job_enqueue_method(job_class, job_method_name, params)
      define_method(job_method_name) do |*args, **kw_args|
        req_args    = params.filter_map { _1[0] == :req ? _1[1] : nil }
        req_kw_args = params.filter_map { _1[0] == :keyreq ? _1[1] : nil }
        self.class.ensure_required_kw_args_present!(req_kw_args, kw_args)
        self.class.ensure_all_args_present!(req_args, args)

        # Instance method adds
        kw_args[:__jobify__record_id] = id
        job_class.perform_later(*args, **kw_args)
      end
    end

    def self.ensure_required_kw_args_present!(req_kw_args, kw_args)
      req_kw_args.each do |key|
        next if kw_args.key?(key)

        raise ::MissingKeywordArgument, "Missing require keyword argument `#{key}`"
      end
    end

    def self.ensure_all_args_present!(req_args, args)
      num_args_required = req_args.size
      num_args_given    = args.size

      return if num_args_given >= num_args_required

      raise ::MissingArgument, "Not enough arguments. Method expects #{num_args_required}. Got #{num_args_given}"
    end

    def ensure_required_kw_args_present!(req_kw_args, kw_args)
      self.class.ensure_required_kw_args_present!(req_kw_args, kw_args)
    end

    def ensure_all_args_present!(req_args, args)
      self.class.ensure_all_args_present!(req_args, args)
    end
  end
end
