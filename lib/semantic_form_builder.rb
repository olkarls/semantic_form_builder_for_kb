require 'action_view'
require 'action_controller'

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  if html_tag =~ /type="hidden"/ || html_tag =~ /<label/
    html_tag
  else
    "<span class=\"error_message\">#{[instance_tag.error_message].flatten.first}</span>"
    "#{html_tag}"
  end
end

module FormHelper
  def semantic_form_for(*args, &block)
    options = args.extract_options!.merge(:builder => SemanticFormBuilder::FormBuilder)
    form_for(*(args + [options]), &block)
  end
end

ActionController::Base.helper(FormHelper)

module SemanticFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder
    %w[text_field collection_select password_field file_field datetime_select select text_area grouped_collection_select].each do |method_name|
      define_method(method_name) do |field_name, *args|
        field_wrapper(method_name, field_name) do
          field_label(field_name, method_name, *args) + 
          super(field_name, *args).html_safe + 
          field_error_or_hint(field_name, *args)
        end
      end
    end
    
    %w[email_field url_field telephone_field phone_field search_field numeric_field].each do |method_name|
      define_method(method_name) do |field_name, *args|
        type = case method_name.to_sym
          when :email_field then :email
          when :url_field then :url
          when :phone_field then :tel
          when :search_field then :search
          when :numeric_field then :number
        end
        
        options = args.extract_options!
        
        field_wrapper(method_name, field_name) do
          field_label(field_name, method_name, *args) + 
          @template.text_field_tag("#{object_name}[#{field_name}]", object.send(field_name), options.stringify_keys.update("type" => type.to_s).merge(:builder => nil, :size => 30)) + 
          field_error_or_hint(field_name, *args)
        end
      end
    end
    
    alias telephone_field phone_field
    
    def check_box(field_name, *args)
      field_wrapper("check_box", field_name) do
        super(field_name, *args).html_safe + 
        field_label(field_name, "check_box", *args) + 
        field_error_or_hint(field_name, *args)
      end
    end
    
    def radio_button(field_name, *args)
      field_wrapper("radio_button", field_name) do
        super(field_name, *args).html_safe + 
        field_label(field_name, "radio_button", *args) + 
        field_error_or_hint(field_name, *args)
      end
    end
    
    def radio_buttons(field_name, collection, value_method = nil, text_method = nil, *args)
      options = args.extract_options!
      
      if collection.first.class == String
        field_wrapper("radio_buttons", field_name, *args) do
          radio_buttons_from_array_collection(field_name, collection) + 
          field_error_or_hint(field_name, *args)
        end
      else
        field_wrapper("radio_buttons", field_name, *args) do
          radio_buttons_from_model_collection(field_name, collection, value_method, text_method) + 
          field_error_or_hint(field_name, *args)
        end
      end
    end
    
    def submit(text = nil, *args)
      text = I18n.translate(:save) if text.blank?
      options = args.extract_options!
      
      options[:name] = "commit" if options[:name].blank?
      @template.content_tag(:button, :class => options[:class], :id => options[:id], :name => options[:name], :type => "submit") do
        @template.content_tag(:span, text, :title => options[:title])
      end
    end
    
    def fieldset(*args, &block)
      options = args.extract_options!
      if block_given?
        legend_tag = ""
        unless options[:legend].blank?
          legend_tag = @template.content_tag(:legend, options[:legend])
        end
        @template.content_tag(:fieldset, legend_tag.html_safe + @template.capture(&block), :class => options[:class], :id => options[:id])
      else
        raise ArgumentError, 'No block given.'
      end
    end
    
    def field_wrapper(method_name = nil, field_name = nil, &block)
      if block_given?
        @template.content_tag(:div, :class => field_wrapper_classes(method_name, field_name), :id => wrapper_id(object_name, field_name)) do
          @template.capture(&block)
        end
      else
        raise ArgumentError, 'No block given.'
      end
    end
    
    def field_label(field_name, method = nil, *args)
      options = args.extract_options!
      options.reverse_merge!(:required => field_required?(field_name))

      classes = []

      unless options[:label_class].blank?
        if options[:label_class].split(" ").length > 1 
          options[:label_class].split(" ").each do |css_class|
            classes << css_class
          end
        else
          classes << options[:label_class]
        end
      end

      classes << "required" if options[:required]
      
      label_text = options[:label]
      label_text = I18n.translate(field_name.to_s.sub("_id", "")).capitalize + ": " if options[:label].blank?
      label_text = "#{label_text} <abbr>*</abbr>".html_safe if options[:required]

      css_classes = nil
      css_classes = classes.join(" ") unless classes.empty?
      
      unless options[:label_for].blank?
        label(field_name, label_text, :class => css_classes, :for => options[:label_for])
      else
        label(field_name, label_text, :class => css_classes)
      end
    end
    
    protected
    
    def field_wrapper_classes(method_name, field_name)
      classes = ["control_wrapper"]
      unless method_name.blank? && field_name.blank?
        classes << [wrapper_class_for_method(method_name)]
        classes << "field_with_error" if has_error?(field_name)
      end
      
      classes << "required" if field_required?(field_name)
      
      classes.join(" ")
    end

    def wrapper_class_for_method(method)
      unless method.blank?
        if method.include?("select") && !method == "datetime_select"
          "select_box"
        else
          method
        end
      end
    end
    
    def wrapper_id(object_name, field_name)
      unless field_name.blank?
        "wrapper_#{object_name.to_s}_#{field_name}"
      else
        nil
      end
    end
    
    def has_error?(field_name)
      object.errors[field_name].any?
    end
    
    def field_error_or_hint(field_name, *args)
      if has_error?(field_name)
        field_error(field_name)
      else
        field_hint(*args)
      end
    end
    
    def field_error(field_name)
      @template.content_tag(:span, object.errors[field_name].flatten.first.sub(/^\^/, ''), :class => 'error_message field_hint')
    end

    def field_hint(*args)
      options = args.extract_options!
      unless options[:hint].blank?
        @template.content_tag(:span, options[:hint], :class => 'field_hint')
      end
    end
    
    def field_required?(field_name)
      object.class.validators_on(field_name).map(&:class).include? ActiveModel::Validations::PresenceValidator
    end
    
    def radio_buttons_from_array_collection(field_name, collection)
      s = ""
      collection.each do |value|
        s += @template.radio_button_tag("#{object.class.to_s.underscore}[#{field_name}]", value)
        s += label(field_name, I18n.translate(value.to_sym), :value => value)
      end      
      @template.content_tag(:div, s.html_safe, :class => "buttons_holder")
    end
    
    def radio_buttons_from_model_collection(field_name, collection, value_method, text_method)
      s = ""
      collection.each do |value|
        s += @template.radio_button_tag("#{object_name}[#{field_name}]", value.send(value_method))
        s += label(field_name, value.send(text_method), :for => "#{object_name}_#{field_name}_#{value.send(value_method)}")
      end
      @template.content_tag(:div, s.html_safe, :class => "buttons_holder")
    end
    
    def objectify_options(options)
      super.except(:label, :required, :label_class, :label_for, :hint)
    end
  end
end