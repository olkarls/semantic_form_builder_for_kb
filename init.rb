# load_paths.each do |path|
#   ActiveSupport::Dependencies.load_once_paths.delete(path)
# end if Rails.development?

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  if html_tag =~ /type="hidden"/ || html_tag =~ /<label/
    html_tag
  else
    "<span class=\"error_message\">#{[instance_tag.error_message].flatten.first}</span>"
    "#{html_tag}"
  end
end

config.to_prepare do
  ApplicationController.helper(FormHelper)
end
