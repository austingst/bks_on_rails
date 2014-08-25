# == Schema Information
#
# Table name: shifts
#
#  id            :integer          not null, primary key
#  restaurant_id :integer
#  start         :datetime
#  end           :datetime
#  period        :string(255)
#  urgency       :string(255)
#  billing_rate  :string(255)
#  notes         :text
#  created_at    :datetime
#  updated_at    :datetime
#

class Shift < ActiveRecord::Base
  include Timeboxable

  belongs_to :restaurant
  has_one :assignment, dependent: :destroy #inverse_of: :shift
    accepts_nested_attributes_for :assignment
  has_one :rider, through: :assignment

  
  classy_enum_attr :billing_rate
  classy_enum_attr :urgency

  validates :restaurant_id, :billing_rate, :urgency,
    presence: true

  def assigned? #output: bool
    !self.assignment.rider.nil?
  end

  def assign_to(rider, status=:proposed) 
    #input: Rider, AssignmentStatus(Symbol) 
    #output: self.Assignment
    params = { rider_id: rider.id, status: status } 
    if self.assigned?
      self.assignment.update params
    else
      self.assignment = Assignment.create! params
    end
  end

  def unassign
    self.assignment.update(rider_id: nil, status: :unassigned) if self.assigned?
  end

  def conflicts_with?(conflicts)
    conflicts.each do |conflict|
      return true if ( conflict.end >= self.end && conflict.start < self.end ) || ( conflict.start <= self.start && conflict.end > self.start ) 
      # ie: if the conflict under examination overlaps with this shift
    end
    false
  end

  def double_books_with?(shifts)
    shifts.each do |shift|
      return true if ( shift.end >= self.end && shift.start <  self.end ) || ( shift.start <= self.start && shift.end > self.start )
      # ie: if the shift under examination overlaps with this shift
    end
    false
  end

  def Shift.batch_update new_shifts
    errors = []
    new_shifts.each do |new_shift|
      
      id = new_shift[:id].to_i
      old_shift = Shift.find(id)
      new_attrs = parse_batch_attrs new_shift
      
      unless old_shift.update_attributes(new_attrs)
        errors.push old_shift.errors
      end
    end
    errors
  end

  private

    def Shift.parse_batch_attrs attrs
      attrs.reject! { |k,v| k == "id" }
      attrs["start"] = parse_date attrs["start"]
      attrs["end"] = parse_date attrs["end"]
      attrs.to_h
    end

    def Shift.parse_date d
      Time.zone.local( d["year"], d["month"], d["day"], d["hour"], d["minute"] )
    end

end
