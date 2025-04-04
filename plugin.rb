# frozen_string_literal: true

# name: add-custom-user-fields-to-serializer
# about: Adds custom user fields to basic_user serializer for topic lists
# version: 0.1
# authors: Don

after_initialize do
  add_to_serializer(:basic_user, :custom_fields, false) do
    object.respond_to?(:custom_fields) ? object.custom_fields || {} : {}
  end
end
