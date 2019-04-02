# frozen_string_literal: true

class HTMLRenderer < Redcarpet::Render::HTML
  def header(text, header_level)
    tag = "h#{header_level}"
    text_as_id = text.downcase.gsub(/[^a-z0-9\-_]+/i, '-')
    %(<#{tag} id="#{text_as_id}">#{text}</#{tag}>)
  end
end
