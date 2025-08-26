# frozen_string_literal: true

# name: add-custom-user-fields-to-serializer
# about: Adds custom user fields to basic_user serializer for topic lists and filters topics by country
# version: 0.5
# authors: Don

# Define a constant for the country field ID for easier configuration
COUNTRY_FIELD_ID = "user_field_13"

after_initialize do
  # Add custom_fields to basic_user serializer
  add_to_serializer(:basic_user, :custom_fields, respect_plugin_enabled: false) do 
    object.respond_to?(:custom_fields) ? object.custom_fields || {} : {} 
  end

  # Add an index to improve performance if it doesn't exist yet
  if !ActiveRecord::Base.connection.index_exists?(:user_custom_fields, [:name, :value])
    begin
      ActiveRecord::Base.connection.add_index :user_custom_fields, [:name, :value], name: 'idx_user_custom_fields_country'
    rescue => e
      Rails.logger.warn("Failed to create index on user_custom_fields: #{e.message}")
    end
  end

  # Add custom country filter to TopicQuery
  TopicQuery.add_custom_filter(:country) do |results, topic_query|
    country = topic_query.options[:country]
    if country.present?
      # Basic sanitization of the country parameter
      country = country.to_s.strip
      
      user_ids = User.joins(:user_custom_fields)
        .where("user_custom_fields.name = ?", COUNTRY_FIELD_ID)
        .where("user_custom_fields.value ILIKE ?", "%(" + country + ")%")
        .pluck(:id)
      
      results = results.where(user_id: user_ids)
    end
    results
  end

  # API endpoint: /topic-country-list/available
  module ::DiscourseTopicCountryList
    class Engine < ::Rails::Engine
      engine_name "discourse_topic_country_list"
      isolate_namespace DiscourseTopicCountryList
    end
  end

  DiscourseTopicCountryList::Engine.routes.draw do
    get "/available" => "countries#index"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseTopicCountryList::Engine, at: "/topic-country-list"
  end

  class DiscourseTopicCountryList::CountriesController < ::ApplicationController
    def index
      begin
        user_ids = Topic.select(:user_id).distinct.pluck(:user_id)

        fields = UserCustomField
          .where(user_id: user_ids, name: COUNTRY_FIELD_ID)
          .pluck(:value)

        countries = fields
          .compact
          .uniq
          .sort

        render_json_dump(
          countries.map do |field|
            match = field.match(/\((.*?)\)/)
            code = match ? match[1].downcase : "global"
            { id: code, name: field }
          end
        )
      rescue => e
        Rails.logger.error("Error in topic-country-list API: #{e.message}")
        render_json_error(e.message, status: 500)
      end
    end
  end
end
