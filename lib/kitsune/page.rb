module Kitsune
  module Page
    def self.included(model)
      model.class_eval do
        admin do
          display :title, :layout, :parent_id, :url
          edit :title, :url, :body, :layout, :parent_id
          wysiwyg :body
          select :layout, Dir.glob(File.join(RAILS_ROOT, 'app', 'views', 'layouts', '*.html.*')).map{|f| File.basename(f).split('.').first}
          
          on_new do |page|
            remove_faux_methods
          end
          
          on_edit do |page|
            Kitsune::Layout.new(Dir.glob(File.join(RAILS_ROOT, 'app', 'views', 'layouts', "#{page.layout}.html.*")).first).content_areas.each do |area|
              page.class.send(:define_method, area, Proc.new{ self.data ||= {}; self.data[:content_for] ||= {}; self.data[:content_for][area.to_sym]})
              edit area.to_sym => :text
              add_faux_method area
            end
          end
          
          before_save do |page|
            Kitsune::Layout.new(Dir.glob(File.join(RAILS_ROOT, 'app', 'views', 'layouts', "#{page.layout}.html.*")).first).content_areas.each do |area|
              page.class.send(:define_method, "#{area}=", Proc.new{|value| self.data ||= {}; self.data[:content_for] ||= {}; self.data[:content_for][area.to_sym] = value})
              add_faux_method "#{area}="
            end
          end
          
        end
        
        before_save :update_url
        belongs_to :page, :foreign_key => "parent_id"
        belongs_to :parent, :class_name => 'Page'
        validate :must_be_kitsune_route
        validates_uniqueness_of :url
        serialize :data
        
        
        def after_save
          ActionController::Routing::Routes.reload!
        end
        
        def after_destroy
          ActionController::Routing::Routes.reload!
        end
        
        def title_for_url
          CGI.escape(title.downcase.gsub(/\s+/, '-')).squeeze('-')
        end
        
        def url_for_page
          parent ? parent.url_for_page + '/' + title_for_url : '/' + title_for_url
        end
        
        def update_url
          write_attribute :url, (url.present? ? url : url_for_page)
        end
        
        def must_be_kitsune_route
          unless ActionController::Routing::Routes.recognize_path(url.present? ? url : url_for_page, :method => :get)[:controller] == 'kitsune'
            errors.add_to_base("URL is already being used")
          end
        rescue
        end
        
      end
    end
  end
end