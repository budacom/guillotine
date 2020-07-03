require 'google/cloud/vision'
require 'faraday_middleware'

module VisionUtils
  extend self

  def get_word_layout(_url, _api_key, timeout: 30)
    extract_word_layout handle_response conn(timeout).post(
      "/v1/images:annotate?key=#{_api_key}",
      'requests' => [
        {
          'image' => build_image_source(_url),
          'features' => [
            { 'type' => 'DOCUMENT_TEXT_DETECTION' }
          ]
        }
      ]
    )
  end

  private

  def build_image_source(_url)
    uri = URI(_url)
    if uri_is_local(uri)
      { 'content' => Base64.encode64(uri.open(&:read)) }
    else
      { 'source' => { 'imageUri': _url } }
    end
  end

  def uri_is_local(_uri)
    return true if _uri.scheme != 'http' && _uri.scheme != 'https'

    _uri.host == 'localhost' || _uri.host == '127.0.0.1'
  end

  def extract_word_layout(_data)
    image_text = _data['responses'].first['fullTextAnnotation']
    return [] if image_text.nil?

    [].tap do |result|
      image_text['pages'].each do |page|
        page['blocks'].each do |block|
          next unless block['blockType'] == 'TEXT'

          block['paragraphs'].each do |para|
            para['words'].each do |w|
              extracted_word = extract_word(w)
              result << extracted_word if extracted_word
            end
          end
        end
      end
    end
  end

  def extract_bounding_box(_vertices)
    [].tap do |bounding_box|
      _vertices.each do |vertex|
        if vertex['x'] == nil || vertex['y'] == nil
          return nil
        end

        bounding_box << [vertex['x'], vertex['y']]
      end
    end
  end

  def extract_word(_raw_word)
    wtext = _raw_word['symbols'].map { |sym| sym['text'] }.join
    confidence = _raw_word['symbols'].map { |sym| sym['confidence'].to_f }.min
    vertices = _raw_word['boundingBox']['vertices']
    bounding_box = extract_bounding_box(vertices)

    if bounding_box == nil
      return nil
    end

    [wtext, bounding_box, confidence]
  end

  def handle_response(_response)
    if _response.status != 200 && _response.status != 201
      raise 'Service error'
    end

    _response.body
  end

  def conn(_timeout)
    @conn ||= Faraday.new(url: "https://vision.googleapis.com") do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter :patron

      faraday.options.timeout = _timeout
      faraday.options.open_timeout = _timeout
    end
  end
end
