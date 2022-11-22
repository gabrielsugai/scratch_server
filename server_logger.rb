class ServerLogger

  def initialize(request)
    @request = request
  end

  def call
    build_log
  end

  private

  def build_log
    "[#{Time.now}] - Method: #{@request.method} | Path: #{@request.path} | Query: #{@request.query} | Body: #{@request.body}"
  end
end
