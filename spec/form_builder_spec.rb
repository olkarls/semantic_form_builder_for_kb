require File.expand_path('spec_helper', File.dirname(__FILE__))

class User < ActiveRecord::Base
end

class SomeController < ActionController::Base
end

module SemanticFormBuilder
  describe FormBuilder do
    before do
      @controller = SomeController.new
      @user = User.new
      @builder = SemanticFormBuilder::FormBuilder.new(:user, @user, @controller.view_context, {}, Proc.new {})
    end

    describe "#text_field" do
      it 'should not include error wrapper when valid' do
        @builder.text_field(:name).should_not have_tag('div.field_with_error')
      end

      it 'should include error wrapper when not valid' do
        @user.errors[:name] << "is required"
        @builder.text_field(:name).should have_tag('div.field_with_error')
      end
    end
  end
end
