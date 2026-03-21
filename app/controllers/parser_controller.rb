class ParserController < ApplicationController
  def iof_runners
    respond_to do |format|
      IofRunnersParser.new.convert

      format.html { redirect_to "#{runners_url}?wre=true", notice: "Datele wre despre sportivi au fost actualizate" }
    end
  end
end
