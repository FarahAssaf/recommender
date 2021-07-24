require 'sinatra'
require 'date'

class Recommender < Sinatra::Base
  get '/' do
    erb :form
  end

  post '/' do
    @file = params[:file][:tempfile]
    process_file
  end

  private

  def process_file
    recommendations = {}
    results = {}
    lines = File.readlines(@file)
    lines = lines.select { |line| valid_input?(line) }
    lines = lines.map{ |line| line.split(' ') }.sort_by{ |line| DateTime.parse([line[0], line[1]].join(' ')) }
    lines.each do |data|
      if data[3] == 'recommends'
        invitee = data[4]
        recommendations[invitee] = { referred_by: data[2] } unless recommendations[invitee]
      elsif data[3] == 'accepts'
        invitee = data[2]
        if recommendations[invitee]
          referral = recommendations[invitee][:referred_by]
          index = 0
          while (referral) do
            results[referral] = (results[referral] || 0) + ((0.5) ** index)
            if recommendations[referral]
              referral = recommendations[referral][:referred_by]
              index += 1
            else
              referral = nil
            end
          end
        end
      end
    end
    results.to_s
  end

  def valid_input?(line)
    recommends_regex = Regexp.new('^([0-9]+(-[0-9]+)+)\\s\\d\\d:\\d\\d\\s[a-zA-Z]+\\srecommends\\s[a-zA-Z]+$', Regexp::IGNORECASE)
    accepts_regex = Regexp.new('^[0-9]{4}-[0-9]{2}-[0-9]{2}\\s\\d\\d:\\d\\d\\s[a-zA-Z]+\\saccepts$', Regexp::IGNORECASE)
    recommends_regex.match?(line) || accepts_regex.match?(line)
  end
end