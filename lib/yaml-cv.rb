require "mustache"
require "yaml"
require "tempfile"
require "uri"
require "open3"


def load_asset(asset_file)
    file_path = File.join(File.dirname(__FILE__), "assets")
    file_path = File.join(file_path, asset_file)
    File.read(file_path)
end

def format_period(period)
    month_names = {
        1 => "Jun",
        2 => "Feb",
        3 => "Mar",
        4 => "Apr",
        5 => "May",
        6 => "Jun",
        7 => "Jul",
        8 => "Aug",
        9 => "Sep",
        10 => "Oct",
        11 => "Nov",
        12 => "Dec"
    }
    index = period["month"]
    period["month"] = month_names[ index ]
    period
end

def format_subsections(subsections)
    if !subsections
        return
    end

    subsections.map { |e|
        if e["from"]
            e["from"] = format_period e["from"]
        end
        if e["to"]
            e["to"] = format_period e["to"]
        end
        e
    }
end

class CV < Mustache

	self.template_file = File.join(File.dirname(__FILE__), "assets/cv.mustache")

	def initialize(file_path)
		@cv = YAML.load_file(file_path)

        if  @cv["contact"]
            @cv["contact"] = @cv["contact"].map { |c|
                c["icon"] = icon(c["icon"])
                c
            }
        end
    end
    
    def details
        @cv["details"]
    end

    def profile
        @cv["profile"]
    end

    def skills
        @cv["skills"]
    end

    def technical
        @cv["technical"]
    end

    def experience
        format_subsections @cv["experience"]
    end

    def education
        format_subsections @cv["education"]
    end
	
	def full_name
		details["last_name"] + " " + details["first_name"]
    end
    
    def css
        load_asset("style.css")
    end

    def contact
        @cv["contact"]
    end

    def contact_padding
        if !contact
            return 0
        end

        columns = (contact.length / 3.0).ceil
        padding = (3 - columns) * 3

        Array.new(padding) { |i| 0 }
    end

    def icon(name)
        load_asset("icons/#{name.strip}.svg")
    end

    def render
        template = load_asset("cv.mustache")
        super(template)
    end

    def write_html(file_path)

        html = render
        File.open(file_path, 'w') { |file| file.write(html) }
    end

    def write_pdf(file_path)

        temp_file = Tempfile.new(["cv", ".html"])
        temp_file << render
        temp_file.flush

        system("wkhtmltopdf #{temp_file.path} #{file_path}")
    end
end