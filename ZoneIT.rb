require "uri"
require "net/http"
require "json"

@next_page_token = ''
@companyName='zoneit'

def fetch_jobs()
    url = URI("https://apply.workable.com/api/v3/accounts/#{@companyName}/jobs")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["authority"] = "apply.workable.com"
    request["accept"] = "application/json, text/plain, */*"
    request["accept-language"] = "en"
    request["content-type"] = "application/json"
    request["origin"] = "https://apply.workable.com"
    request["referer"] = "https://apply.workable.com/#{@companyName}/"
    request["sec-ch-ua"] = "\"Chromium\";v=\"110\", \"Not A(Brand\";v=\"24\", \"Google Chrome\";v=\"110\""
    request["sec-ch-ua-mobile"] = "?0"
    request["sec-ch-ua-platform"] = "\"macOS\""
    request["sec-fetch-dest"] = "empty"
    request["sec-fetch-mode"] = "cors"
    request["sec-fetch-site"] = "same-origin"
    request["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
    
    request_body = {
        "query": "",
        "location": [],
        "department": [],
        "worktype": [],
        "remote": []
        }
    
    request_body['token'] = @next_page_token unless @next_page_token == ''
    request.body = JSON.dump(request_body)

    response = https.request(request)
    json_data = JSON.parse(response.read_body)
    @next_page_token = json_data['nextPage']
    return json_data
end

def fetch_details(shortcode)
    url = URI("https://apply.workable.com/api/v2/accounts/#{@companyName}/jobs/#{shortcode}")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["authority"] = "apply.workable.com"
    request["accept"] = "application/json, text/plain, */*"
    request["accept-language"] = "en"
    request["sec-ch-ua"] = "\"Chromium\";v=\"110\", \"Not A(Brand\";v=\"24\", \"Google Chrome\";v=\"110\""
    request["sec-ch-ua-mobile"] = "?0"
    request["sec-ch-ua-platform"] = "\"macOS\""
    request["sec-fetch-dest"] = "empty"
    request["sec-fetch-mode"] = "cors"
    request["sec-fetch-site"] = "same-origin"
    request["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
    request["referer"] = "https://apply.workable.com/#{@companyName}/j/#{shortcode}/"
    response = https.request(request)
    
    if [404, 500, 502].include? response.code.to_i
        raise "Error fetching data from API - #{response.code}"
    end
    json_data = JSON.parse(response.body)
    # puts json_data
    desc = ''
    desc += json_data["description"] if json_data["description"]
    desc += "<strong>Requirements</strong><br />" if json_data["requirements"]
    desc += json_data["requirements"] if json_data["requirements"]
    desc += "<strong>Benefits</strong><br />" if json_data["benefits"]
    desc += json_data["benefits"] if json_data["benefits"]
    return desc
end

results = fetch_jobs()
totalJobCount = results["total"]
jobs = results["results"]
data = []

puts totalJobCount

while !@next_page_token.nil?
    for job in jobs
        puts "getting job..."
        puts job["shortcode"]
        details = fetch_details(job["shortcode"])
        job = {
            "id": job["shortcode"],
            "location": job["location"]["city"] + ' ' + job["location"]["country"],
            "jobtype": job["type"],
            "description": details,
            "published": job["published"],
            "title": job["title"],
            "url": "https://apply.workable.com/#{@companyName}/j/#{job["shortcode"]}"
        }
    
        data << job
    
    end
    jobs = fetch_jobs()['results']
end
for job in jobs
    puts "getting job..."
    puts job["shortcode"]
    details = fetch_details(job["shortcode"])
    job = {
        "id": job["shortcode"],
        "location": job["location"]["city"] + ' ' + job["location"]["country"],
        "jobtype": job["type"],
        "description": details,
        "published": job["published"],
        "title": job["title"],
        "url": "https://apply.workable.com/#{@companyName}/j/#{job["shortcode"]}"
    }

    data << job
end

json_data = {
    jobCount: totalJobCount,
    jobs: data
}

file = File.new("#{@companyName}.json", 'w')
file.write(JSON.pretty_generate(json_data))
file.close

{ output_file: file.path }