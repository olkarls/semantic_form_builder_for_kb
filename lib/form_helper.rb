module FormHelper
  def semantic_form_for(*args, &block)
    options = args.extract_options!.merge(:builder => SemanticFormBuilder::FormBuilder)
    form_for(*(args + [options]), &block)
  end
end