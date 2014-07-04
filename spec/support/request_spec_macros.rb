module RequestSpecMacros
  #methods
  def check_nav_links
    links = [
      { text: 'Home' ,    new_page_title: '' },
      { text: 'Manual',   new_page_title: 'Manual' }
    ]
    links.each do |link|
      check_nav_link(link[:text], link[:new_page_title])
    end
  end

  def check_nav_link(link, title)
    click_link link
    expect(page).to have_title(full_title(title))
  end

  #custom matchers  
end