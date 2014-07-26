# == Schema Information
#
# Table name: riders
#
#  id         :integer          not null, primary key
#  active     :boolean
#  created_at :datetime
#  updated_at :datetime
#

class Rider < ActiveRecord::Base
  include User, Contactable, Equipable, Locatable # app/models/concerns/

  #nested attributes
  has_one :qualification_set, dependent: :destroy
    accepts_nested_attributes_for :qualification_set
  has_one  :skill_set, dependent: :destroy
    accepts_nested_attributes_for :skill_set
  has_one :rider_rating, dependent: :destroy
    accepts_nested_attributes_for :rider_rating
  
  #associations
  has_many :assignments
  has_many :shifts, through: :assignments
  has_many :conflicts 

  validates :active, 
    presence: true,
    inclusion: { in: [ true, false ] }

  def name
    self.contact.name
  end

  def assignments_on(date) #input: date obj, #output Arr of Assignments (possibly empty)
    self.assignments.joins(:shift).where( shifts: { start: (date.beginning_of_day..date.end_of_day) } )
  end

  def conflicts_on(date) #input: date obj, #output Arr of Conflicts (possibly empty)
    self.conflicts.where( start: (date.beginning_of_day..date.end_of_day) )
  end
end
