class Table < ApplicationController
  include Paths
  attr_accessor :spans, :headers, :rows, :form

  def initialize record_type, records, caller, base_path, filter_path_params='', options={}
    #input: Sym, Arr of ActiveRecords, Sym, Str, Hash of form:
      # { teaser: <Bool>, form: <Bool> }
    #output: Table obj

    #store private attributes
    @record_type = record_type
    @caller = caller
    @base_path = base_path
    @filter_path_params = filter_path_params
    @teaser = options[:teaser] || false 
    @form = options[:form] || false

    #load public attributes
    @spans = load_spans options
    @headers = load_headers options
    @rows = load_rows records, options
  end

  private

  ### SPANS ###
  def load_spans options
    case @record_type
    when :shift 
      if options[:review_points]
        [2,1,1,1,2,1,3]
      else
        trim_array_by_caller [2,3,1,1,2,2]# arg is arr of span widths
      end
    when :conflict
      trim_array_by_caller [2,3,1]
    end
  end

  ### HEADERS ###
  def load_headers options
    #output: Arr of Hashes of type: { val: <Str>, sortable: <Bool>[OPTIONAL], sort_key: <Str>[OPTIONAL] }
    if options[:review_points]
      headers = review_points_headers
    else
      default = default_headers
      headers = trim_array_by_caller default
    end
    headers.map { |h| header_from h }
  end

  # helpers for load_headers
  def default_headers
    case @record_type
    when :shift
      default_shift_headers
    when :conflict
      default_conflict_headers
    end
  end

  def review_points_headers
    [ 
      { val: 'Restaurant', sort_key: 'mini_contacts.name' }, 
      { val: 'Time', sort_key: 'start' },
      { val: 'Billing', sort_key: 'billing_rate' },
      { val: 'Urgency', sort_key: 'urgency' },
      { val: 'Rider', sort_key: 'contacts.name' },
      { val: 'Status', sort_key: 'assignments.status' },
      { val: 'Notes', sort_key: 'assignments.notes' } 
    ]
  end

  def default_shift_headers
    #output: Arr of Hashes
    [ 
      { val: 'Restaurant', sort_key: 'mini_contacts.name' }, 
      { val: 'Time', sort_key: 'start' },
      { val: 'Billing', sort_key: 'billing_rate' },
      { val: 'Urgency', sort_key: 'urgency' },
      { val: 'Assigned to', sort_key: 'contacts.name' },
      { val: 'Status', sort_key: 'assignments.status' }
    ]
  end

  def default_conflict_headers
    #output: Arr of Hashes
    [ 
      { val: 'Rider', sort_key: 'contacts.name' },
      { val: 'Time',  sort_key: 'start'},
      { val: 'Period', sort_key: 'period' }
    ]
  end

  def header_from hh
    #input: Hash of type: { val: <Str>, sort_key: <Str (corr to SQL query term)> }
    #does: Parses context (teaser or no) and appends or doesn't append sortable k/v pairs to header hash accordingly
    #output Hash of type: { val: <Str>, sortable: <Bool>[OPTIONAL], sort_key: <Str>[OPTIONAL] }
    { val: hh[:val], sort_key: @teaser ? nil : hh[:sort_key] }
  end

  ### ROWS ###
  def load_rows records, options
    #input: records(Arr of ActiveRecord Objs), @caller(Sym)[IMPLICIT], @
    #output: Arr of Hashes of form: { val: <Str>, href: <Str of type Path> }
    records.map{ |record| row_from record, options }
  end

  def row_from record, options
    row = { 
      checkbox: { name: 'ids[]', val: record.id },
      cells: cells_from(record, options)
      # actions: actions_from(record, options) 
    }
  end

  ### CELLS ###
  def cells_from record, options
    if options[:review_points]
      cells = review_points_cell_procs
    else
      default = default_cell_procs_from record
      cells = trim_array_by_caller default
    end
    cells.map{ |proc| proc.call record  }
  end

  #helpers for cells_from
  def default_cell_procs_from record
    case @record_type
    when :shift
      default_shift_cell_procs
    when :conflict
      default_conflict_cell_procs
    end  
  end

  def review_points_cell_procs
    [ 
      Proc.new{ |s| { val: s.restaurant.name, href: "/restaurants/#{s.restaurant.id}" } }, #Restaurant
      Proc.new{ |s| { val: s.review_points_time } }, #Time
      Proc.new{ |s| { val: s.billing_rate.text } }, #Billing
      Proc.new{ |s| { val: s.urgency.text } }, #Urgency
      Proc.new{ |s| rider_cell_from s }, #Rider
      Proc.new{ |s| { val: s.assignment.status.text } }, #Status 
      Proc.new{ |s| { val: s.assignment.notes || '--' } } #Status  
    ]
  end

  def default_shift_cell_procs
    [ 
      Proc.new{ |s| { val: s.restaurant.name, href: "/restaurants/#{s.restaurant.id}" } }, #Restaurant
      Proc.new{ |s| { val: s.table_time } }, #Time
      Proc.new{ |s| { val: s.billing_rate.text } }, #Billing
      Proc.new{ |s| { val: s.urgency.text } }, #Urgency
      Proc.new{ |s| rider_cell_from s }, #Rider
      Proc.new{ |s| { val: s.assignment.status.text } } #Status 
    ]
  end

  def rider_cell_from s
    if s.assigned?
      { val: s.rider.name, href: "/riders/#{s.rider.id}" }
    else
      { val: '--' }
    end
  end

  def default_conflict_cell_procs
    [
      Proc.new{ |c| { val: c.rider.name } }, #Rider
      Proc.new{ |c| { val: c.table_time } }, #Time
      Proc.new{ |c| { val: c.period.text.upcase } } #Period
    ]
  end


  ### ACTIONS ###
  # def actions_from record, options
  #   case @record_type
  #   when :shift
  #     if options[:review_points]
  #       review_points_actions.map{ |proc| proc.call record }
  #     else
  #       shift_actions.map { |proc| proc.call record }
  #     end
  #   when :conflict
  #     conflict_actions.map { |proc| proc.call record }
  #   end
  # end

  # helpers for actions_from

  # def review_points_actions
  #   [
  #     Proc.new { |s| { val: 'Edit Assignment', href: edit_path(s.assignment, :assignments).sub('/shifts/review_points/', '/shifts/') } },
  #     Proc.new { |s| { val: 'Edit Shift', href: edit_path(s, :shifts).sub('/shifts/review_points/', '/shifts/') } }
  #   ]
  # end

  # def shift_actions
  #   [
  #     Proc.new { |s| { val: assign_str_from(s), href: edit_path(s.assignment, :assignments) } },
  #     Proc.new { |s| { val: 'Assignment Details', href: show_path(s.assignment, :assignments) } },
  #     Proc.new { |s| { val: 'Edit Shift', href: edit_path(s, :shifts) } },
  #     Proc.new { |s| { val: 'Shift Details', href: show_path(s, :shifts) } },
  #     Proc.new { |s| { val: 'Delete', href: show_path(s, :shifts), method: :delete, data: { confirm: 'Are you sure?' } } } 
  #   ]
  # end

  # def assign_str_from s
  #   s.assigned? ? 'Edit Assignment' : 'Assign Shift'
  # end

  # def conflict_actions
  #   rec_type = @teaser ? :conflicts : nil
  #   [
  #     Proc.new{ |c| { val: 'Edit', href: edit_path(c, rec_type) } },
  #     Proc.new { |c| { val: 'Delete', href: show_path(c, rec_type), method: :delete, data: { confirm: 'Are you sure?' } } }
  #   ]
  # end
    
  ### UTILITIES ###

  #TRIM ARR
  def trim_array_by_caller arr
    #input: Arr of Ints (specifying span widths)
    case @record_type
    when :shift
      trim_shift_arr_by_caller arr
    when :conflict
      trim_conflict_arr_by_caller arr
    end
  end

  # helpers for trim_arr_by_caller

  def trim_shift_arr_by_caller arr
    case @caller
    when :restaurant
      arr.delete_at(0)
    when :rider
      arr.delete_at(3)
    end
    arr    
  end

  def trim_conflict_arr_by_caller arr
    if @caller == :rider
      arr.delete_at(0)
    end
    arr
  end
end
