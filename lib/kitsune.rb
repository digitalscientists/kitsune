require 'kitsune/active_record'
require 'kitsune/extensions/routes'
require 'kitsune/form_helper_ext'

module Kitsune
  autoload :FauxColumn, 'kitsune/faux_column'
  autoload :Inspector, 'kitsune/inspector'
  autoload :Page, 'kitsune/page'
  class << self
    def version
      '0.2.0'
    end
    
    def authenticate
      @authenticate ||= false
    end
    
    def authenticate=(do_authenticate)
      @authenticate = do_authenticate
    end
  
    def model_paths # abstract this to something else
      @models_paths ||= ["#{RAILS_ROOT}/app/models"]
    end
    
    def model_paths=(paths)
      @model_paths = paths
    end
    
    def models_with_admin
      models.select{|m| m.respond_to?(:kitsune_admin) && !m.kitsune_admin[:no_admin]} # quacks like a duck
    end
    
    def models
      models = []
      model_paths.each do |path|
        Dir.glob(path+'/*').each do |file|
          begin
            klass = File.basename(file).gsub(/^(.+).rb/, '\1').classify.constantize
            if defined? ::ActiveRecord
              models << klass if klass.ancestors.include?(::ActiveRecord::Base)
            else defined? ::MongoMapper
              models << klass if klass.ancestors.include?(::MongoMapper::Document)
            end
          rescue Exception => e
            # not valid
          end
        end
      end
      models
    end
  end
end
