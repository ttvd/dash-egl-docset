require 'rubygems'
require 'mechanize'
require 'sqlite3'

EXTRACT_EGL_PAGE   = "http://www.khronos.org/registry/egl/sdk/docs/man/html"
EXTRACT_EGL_DB     = "../docSet.dsidx"

a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
}

# Remove any previous files.
if File.exists? EXTRACT_EGL_DB
    File.unlink EXTRACT_EGL_DB
end

# Create sqlite db.
db = SQLite3::Database.new(EXTRACT_EGL_DB)
db.execute "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"

a.get(EXTRACT_EGL_PAGE + "/indexflat.php") do |page|

    # Grab all links on this page.
    page_links = page.links

    # Go through all links
    page_links.each do |link|

        # Skip non functional links.
        if link.attributes['target'].nil?
            next
        end

        # Skip introduction link.
        if link.to_s == "Introduction"
            next
        end

        # At this point we should have only valid egl entries.
        link_file = "#{link.to_s}.xhtml"

        # See if we need to remove previous file.
        if File.exist? link_file
            File.delete link_file
        end

        # Grab corresponding page.
        a.get(EXTRACT_EGL_PAGE + "/#{link.uri.to_s}").save_as link_file

        # Insert into db.
        db.execute "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{link.to_s}', 'Function', '#{link_file}');"
    end
end

db.close
