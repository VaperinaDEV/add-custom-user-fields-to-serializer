# frozen_string_literal: true

# name: add-country-to-serializer
# about: Adds user_field_13 (e.g. country) to basic_user serializer for topic lists
# version: 0.1
# authors: Don

after_initialize do
  add_to_serializer(:basic_user, :user_field_13, false) do
    object.respond_to?(:custom_fields) ? object.custom_fields["user_field_13"] : nil
  end
end
