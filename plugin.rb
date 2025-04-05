# frozen_string_literal: true

# name: add-custom-user-fields-to-serializer
# about: Adds custom user fields to basic_user serializer for topic lists and filters topics by country
# version: 0.1
# authors: Don

after_initialize do
  # Add custom_fields to basic_user serializer
  add_to_serializer(:basic_user, :custom_fields, false) do
    object.respond_to?(:custom_fields) ? object.custom_fields || {} : {}
  end

  # Add custom country filter to TopicQuery
  TopicQuery.add_custom_filter(:country) do |results, topic_query|
    country = topic_query.options[:country]
    if country.present?
      user_ids = User.joins(:user_custom_fields)
                     .where("user_custom_fields.name = ? AND user_custom_fields.value ILIKE ?", "user_field_13", "%(#{country})%")
                     .pluck(:id)
      results = results.where(user_id: user_ids)
    end
    results
  end
end
