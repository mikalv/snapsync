require 'pathname'
require 'logging'
require 'securerandom'
require 'rexml/document'
require "snapsync/version"
require "snapsync/exceptions"
require "snapsync/snapper_config"
require "snapsync/snapshot"
require "snapsync/local_target"
require "snapsync/local_sync"
require 'snapsync/default_sync_policy'

module Logging
    module Installer
        def logger
            @logger ||= Logging.logger[self]
        end
    end

    module Forwarder
        ::Logging::LEVELS.each do |name, _|
            puts name
            define_method name do |*args, &block|
                logger.send(name, *args, &block)
            end
        end
    end
end

class Module
    def install_root_logging(level: 'INFO', forward: true, &block)
        extend Logging::Installer
        if block_given?
            yield(logger)
        else
            logger.add_appenders Logging.appenders.stdout
        end

        if forward
            singleton_class.class_eval do
                install_logging_forwarder
            end
        end
        logger.level = level
    end

    def install_logging_forwarder
        ::Logging::LEVELS.each do |name, _|
            define_method name do |*args, &block|
                logger.send(name, *args, &block)
            end
        end
    end

    def install_logging(forward: true, &block)
        extend Logging::Installer
        if forward
            singleton_class.class_eval do
                install_logging_forwarder
            end
        end
    end
end

class Class
    def install_logging(forward: true, on_instance: false)
        super(forward: forward)
        if on_instance
            include Logging::Installer
            if forward
                install_logging_forwarder
            end
        end
    end
end

module Snapsync
    install_root_logging(forward: true)
end

