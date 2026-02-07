class MetaTags
  # Helps rendering title and meta tags consistently for SEO
  #
  # To set meta tags in a view:
  #
  #   <% Current.meta_tags.set(title: "Example", description: "This is a page.") %>
  #
  # Meta tags can also be set from an object like a database record:
  #
  #   <% Current.meta_tags.set_from(@blog_post) %>
  #
  # This will call `to_meta_tags` on the object which should return a Hash of title, description, etc.
  #
  #   def to_meta_tags
  #     {
  #       title: name,
  #       description: short_description
  #     }
  #   end
  #
  # Render meta tags in the head tag:
  #
  #   <%= render Current.meta_tags %>

  include ActiveModel::Model
  include ActiveModel::Attributes

  class_attribute :default_title
  class_attribute :default_description
  class_attribute :default_image, default: "opengraph.png"
  class_attribute :default_twitter_site

  # Page details
  attribute :site, default: Jumpstart.config.application_name
  attribute :title, default: -> { default_title } # 50 - 60 characters (for site + separator + title)
  attribute :description, default: -> { default_description } # 140 - 160 characters recommended
  attribute :image, default: -> { default_image } # A full URL or filename for an image in the asset pipeline

  # Social media
  attribute :current_url
  attribute :og_type, default: "website" # website | profile | article | video.movie
  attribute :twitter_type, default: "summary" # summary | summary_large_image
  attribute :twitter_site, default: -> { default_twitter_site } # @username

  # General meta tags
  attribute :theme_color, default: "#ffffff"
  attribute :canonical_url
  attribute :next_url
  attribute :prev_url
  attribute :web_app_capable, default: true
  attribute :noindex
  attribute :icons, default: [{href: "/favicon.ico", sizes: :any}, {href: "/icon.svg", type: "image/svg+xml", sizes: :any}]
  attribute :apple_touch_icon, default: "/apple-touch-icon.png"

  # Separator for title & site
  attribute :separator, default: "|"

  def set(new_attributes)
    assign_attributes(new_attributes.compact_blank)
    nil
  end

  def set_from(object)
    assign_attributes(object.to_meta_tags.compact_blank)
    nil
  end

  def render_in(view_context)
    self.current_url ||= view_context.request.url
    full_title = [view_context.content_for(:title) || title, site].compact.join(" #{separator} ")
    image_url = image.start_with?("http") ? image : view_context.image_url(image)

    view_context.render inline: <<~CONTENT, locals: {full_title: full_title, image_url: image_url}.merge(attributes.symbolize_keys)
      <%= tag.title full_title %>
      <%= tag.meta name: :title, content: full_title %>
      <%= tag.meta name: :description, content: description %>
      <%= tag.meta property: "og:type", content: og_type %>
      <%= tag.meta property: "og:url", content: current_url %>
      <%= tag.meta property: "og:title", content: full_title %>
      <%= tag.meta property: "og:description", content: description %>
      <%= tag.meta property: "og:image", content: image_url %>
      <%= tag.meta name: "twitter:card", content: twitter_type %>
      <%= tag.meta(name: "twitter:site", content: twitter_site) if twitter_site %>
      <%= tag.meta name: "twitter:title", content: full_title %>
      <%= tag.meta name: "twitter:description", content: description %>
      <%= tag.meta name: "twitter:image", content: image_url %>
      <% icons.each do |attributes| %>
        <%= tag.link rel: :icon, **attributes %>
      <% end %>
      <%= tag.link rel: "apple-touch-icon", href: apple_touch_icon %>
      <%= tag.meta name: "application-name", content: site %>
      <%= tag.meta(name: :robots, content: :noindex) if noindex %>
      <%= tag.meta(name: "mobile-web-app-capable", content: :yes) if web_app_capable %>
      <%= tag.link(rel: :canonical, href: canonical_url) if canonical_url %>
      <%= tag.link(rel: :prev, href: prev_url) if prev_url %>
      <%= tag.link(rel: :next, href: next_url) if next_url %>
    CONTENT
  end

  def format
    :html
  end
end
