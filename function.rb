# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html


  if event["path"] != '/' && event["path"] != '/token'
    response(status: 404)

  else

    case event["httpMethod"]

    when 'POST'
      headers = event["headers"]
      puts(event["path"])
      puts(headers["Content-Type"])

      if event["path"] != '/token'
        response(status: 405)

      elsif headers["Content-type"] != "application/json"
        response(status: 415)
      else
        # Generate a token
        payload = {
            data: event["body"],
            exp: Time.now.to_i + 5,
            nbf: Time.now.to_i + 2
        }
        token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'

        response(body: {
            'headers' => { 'Content-Type' => 'application/json' },
            'token' => token
        }, status: 201)
      end
    when 'GET'
      puts(event["path"])
      if event["path"] == '/token'
        response(status: 405)
      else
        headerData = event["headers"]
        to_be_validated = headerData["Authorization"]
        puts(to_be_validated)
        validated_token = to_be_validated.delete "Bearer "
        puts(validated_token)
        decoded_token = JWT.decode validated_token, ENV['JWT_SECRET'], 'HS256'
        response(body: decoded_token["data"],status: 201)
      end
    else
      response(status: 405)
    end

  end


end

def response(body: nil, status: 200)
  {
      body: body ? body.to_json + "\n" : '',
      statusCode: status
  }
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
      'body' => '{"name": "bboe"}',
      'headers' => { 'Content-Type' => "application/json" },
      'httpMethod' => 'POST',
      'path' => '/token'
  })

  # Generate a token
  payload = {
      data: { user_id: 128 },
      exp: Time.now.to_i + 1,
      nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # Call /
  PP.pp main(context: {}, event: {
      'headers' => { 'Authorization' => "Bearer #{token}",
                     'Content-Type' => 'application/json' },
      'httpMethod' => 'GET',
      'path' => '/'
  })
end




rescue JWT::ImmatureSignature
response(status: 401)
rescue JWT::ExpiredSignature
response(status: 401)