class Week
  include TimeboxableHelper

  attr_accessor :start, :end, :klass, :records, :record_hash

  def initialize start_time, end_time, record_klass
    @start = start_time.beginning_of_day
    @end = end_time.beginning_of_day + 24.hours
    @klass = record_klass

    @records = load_records
    @record_hash = load_record_hash
  end

  DAYS = [ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' ]
  PERIODS = [ 'AM', 'PM' ]

  HEADERS = [ 'Mon AM','Mon PM','Tue AM','Tue PM','Wed AM','Wed PM','Thu AM','Thu PM','Fri AM','Fri PM', 'Sat AM', 'Sat PM', 'Sun AM', 'Sun PM' ]
  SELECTORS = [ 'mon_am','mon_pm','tue_am','tue_pm','wed_am','wed_pm','thu_am','thu_pm','fri_am','fri_pm', 'sat_am', 'sat_pm', 'sun_am', 'sun_pm']

  def records_for day_period, entity_hash

    entity_key = entity_hash.keys[0]
    entity = entity_hash.values[0]
    rh_key = day_period.to_sym

    records = @record_hash[rh_key]

    if records.nil?
      matches = []
    else
      matches = records.select do |r|
        r.send(entity_key) == entity #TODO: rewrite this?
      end
    end
    matches
  end

  def bg_color_for status
    case status
    when AssignmentStatus::Unassigned
      'red'
    when AssignmentStatus::Proposed
      'orange'
    when AssignmentStatus::Delegated
      'yellow'
    when AssignmentStatus::Confirmed
      'green'
    when AssignmentStatus::CancelledByRider
      'gray'
    when AssignmentStatus::CancelledByRestaurant
      'gray'
    end
  end

  private

    def load_records
      case @klass.to_s
      when 'Shift'
        Shift
          .includes({ rider: :contact } , { restaurant: :mini_contact })
          .where("start > ? AND start < ?", @start, @end )
          .to_a
      when 'Conflict'
        Conflict
          .includes(rider: :contact)
          .where("start > ? AND start < ?", @start, @end )
          .to_a
      end
    end

    def load_record_hash
      acc = {
        mon_am: [],
        mon_pm: [],
        tue_am: [],
        tue_pm: [],
        wed_am: [],
        wed_pm: [],
        thu_am: [],
        thu_pm: [],
        fri_am: [],
        fri_pm: [],
        sat_am: [],
        sat_pm: [],
        sun_am: [],
        sun_pm: []
      }
      @records.inject(acc){ |acc_,r| group_one(acc_,r) }
    end

    def group_one acc, rec
        offset = ((rec.start.beginning_of_day - @start) / 86400).ceil
        per = rec.period.to_s
        if per == 'double'
          keys = assign_double(offset)
          acc[keys[0]] << rec
          acc[keys[1]] << rec
        else
          key = assign([offset,per])
          acc[key] << rec
        end
        acc
    end

    # assign(Arr[Int,Per]) -> Sym
    def assign pair
      case pair
      when [0,'am']
        :mon_am
      when [0,'pm']
        :mon_pm
      when [1,'am']
        :tue_am
      when [1,'pm']
        :tue_pm
      when [2,'am']
        :wed_am
      when [2,'pm']
        :wed_pm
      when [3,'am']
        :thu_am
      when [3,'pm']
        :thu_pm
      when [4,'am']
        :fri_am
      when [4,'pm']
        :fri_pm
      when [5,'am']
        :sat_am
      when [5,'pm']
        :sat_pm
      when [6,'am']
        :sun_am
      when [6,'pm']
        :sun_pm
      end
    end

    # assign_double(Int) -> [Sym,Sym]
    def assign_double offset
      case offset
      when 0
        [:mon_am, :mon_pm]
      when 1
        [:tue_am, :tue_pm]
      when 2
        [:wed_am, :wed_pm]
      when 3
        [:thu_am, :thu_pm]
      when 4
        [:fri_am, :fri_pm]
      when 5
        [:sat_am, :sat_pm]
      when 6
        [:sun_am, :sun_pm]
      end
    end

end
