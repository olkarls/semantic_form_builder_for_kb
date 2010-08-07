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
        s = field_wrapper(method_name, field_name, *args)
        
        s +=  field_label(field_name, *args) + "\r\n  "
        
        s +=  super(field_name, *args) + "\r\n"
        
=begin
        unless field_hint(*args) == ''
          s += "  "
          s += field_hint(*args)
        end
        
        unless field_error(field_name) == ''
          s += "  "
          s += field_error(field_name) + "\r\n"
        end
=end        
        s += form_feedback(field_name, *args)
        
        s += "</div>"
        return s
      end
    end
    
    def radio_buttons(field_name, collection, *args)
      s = field_wrapper("radio_buttons", field_name, *args)
      options = args.extract_options!
      
      s += "<div class=\"buttons_holder\">"
      collection.each do |value|
        s += radio_button(field_name, value) + "\n"
        s += label(field_name, "#{I18n.translate(value.to_sym)}", :value => value) + "\n"
      end
      s += "</div>"
      s += form_feedback(field_name, *args)
      s + "</div>"
    end
    
    def form_feedback(field_name, *args)
      options = args.extract_options!      
      if object.errors.invalid? field_name
        @template.content_tag(:span, [object.errors.on(field_name)].flatten.first.sub(/^\^/, ''), :class => 'field_hint')
      else
        unless options[:hint].blank?
          @template.content_tag(:span, options[:hint], :class => 'field_hint')
        else
          ''
        end
      end
    end
    
    def field_wrapper(method_name, field_name, *args)
      options = args.extract_options!
      classes = "control_wrapper #{method_name}"
      
      if field_error(field_name).length > 1
        classes += " field_with_error"
      end
      
      if options.has_key?(:disabled)
        classes += " disabled"
      end
      
      s = "<div id=\"wrapper_#{object_name}_#{field_name}\" class=\"#{classes}\">\r\n  ".gsub(/[\[\]]/, '_').gsub(/_+/, "_")
    end

    def check_box(field_name, *args)
      s = field_wrapper("check_box", field_name)
      s += super + " " + field_error(field_name) + field_label(field_name, "check_box", *args)
      s += "</div>"
      return s
    end

    def submit(text="#{I18n.translate(:save).capitalize}", *args)
      options = args.extract_options!
      classes = options[:class]
      
      disabled = ""
      
      if options.has_key?(:disabled)
        disabled = " disabled=\"disabled\""
      end
      
      value = ""
      
      if options.has_key?(:value)
        value = " value=\"#{options[:value]}\""
      end
      
      #if options.has_key(:name)
      
      #options.each do |key, value| 
      #  puts "#{key}=\"#{value}\""
      #end
      
      if classes.nil?
        "<button name=\"commit\" type=\"submit\"#{disabled}#{value}><span>#{text}</span></button>"
      else
        "<button name=\"commit\" type=\"submit\"#{disabled}#{value} class=\"#{classes}\"><span>#{text}</span></button>"
      end
    end

    def many_check_boxes(name, subobjects, id_method, name_method, options = {})
      s = ""
      field_name = "#{object_name}[#{name}][]"
      s += field_wrapper('check_boxes', field_name)
      i = 0 
      subobjects.map do |subobject, index|
        s += "<div>"
        s += @template.check_box_tag(field_name, subobject.send(id_method), object.send(name).include?(subobject.send(id_method)), :id => "property_#{i}")
        s += @template.label_tag(field_name, I18n.translate(subobject.send(name_method)), :for => "property_#{i}")
        s += @template.hidden_field_tag(field_name, "", :id => nil)
        s += "</div>"
        i = i + 1
      end
      s + "</div>"
    end

    def error_messages(*args)
      @template.render_error_messages(object, *args)
    end

    private

    def field_error(field_name)
      if object.errors.invalid? field_name
        @template.content_tag(:span, [object.errors.on(field_name)].flatten.first.sub(/^\^/, ''), :class => 'error_message')
      else
        ''
      end
    end
    
    def field_hint(*args)
      options = args.extract_options!
      unless options[:hint].blank?
        @template.content_tag(:p, options[:hint], :class => 'field_hint')
      else
        ''
      end
    end

    def field_label(field_name, method = "", *args)
      options = args.extract_options!
      options.reverse_merge!(:required => field_required?(field_name))
      
      required = false
      
      if options[:required]
        required = true
        if options[:label_class].blank?
          options[:label_class] = "required"
        else
          options[:label_class] += " required"
        end
      end
      
      label_text = ""
      
      if options[:label].blank?
        label_text = I18n.translate(field_name.to_s.gsub("_id", "").intern).capitalize + ": "
      else
        label_text = options[:label]
      end
      
      if required
        if method == "check_box" || method == "radio_button"
          label_text = "<abbr>*</abbr>" + label_text
        else
          label_text += "<abbr>*</abbr>"
        end
      end
      
      label(field_name, label_text, :class => options[:label_class])
    end

    def field_required?(field_name)
      if defined?(object.class.reflect_on_validations_for)
        object.class.reflect_on_validations_for(field_name).map(&:macro).include?(:validates_presence_of)
      end
    end

    def objectify_options(options)
      super.except(:label, :required, :label_class, :hint)
    end
  end
end
