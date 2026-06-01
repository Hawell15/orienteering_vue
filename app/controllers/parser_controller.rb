class ParserController < ApplicationController
  before_action :require_admin!

  def index; end

  def file_results
    return unless params[:path]

    respond_to do |format|
      path         = params[:path].tempfile.path
      parser = if path[/json$/]
        JsonParser.new(path)
      elsif path[/html$/]
        HtmlParser.new(path)
      end

      @competition = parser.convert
      format.html { redirect_to competition_url(@competition), notice: "Competitia a fost creata cu succes" }
    end
  end

  def file_relay_results
    respond_to do |format|
      path       = params[:path].tempfile.path
      relay_type = params[:relay_type].presence || "classic"

      parser = if path[/json$/]
        RelayJsonParser.new(path, relay_type: relay_type)
      elsif path[/html$/]
        RelayHtmlParser.new(path, relay_type: relay_type)
      end

      @competition = parser.convert
      format.html { redirect_to competition_url(@competition), notice: "Competitia a fost creata cu succes" }
    end
  end

  def iof_runners
    respond_to do |format|
      IofRunnersParser.new.convert

      format.html { redirect_to "#{runners_url}?wre=true", notice: "Datele wre despre sportivi au fost actualizate" }
    end
  end

  def iof_results
    respond_to do |format|
      IofResultsParser.new.convert

      format.html { redirect_to "#{runners_url}?wre=true", notice: "Datele wre despre sportivi au fost actualizate" }
    end
  end
end
