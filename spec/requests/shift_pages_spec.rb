require 'spec_helper'
include CustomMatchers, RequestSpecMacros, ShiftRequestMacros, GridRequestMacros

describe "Shift Requests" do
  load_riders_and_restaurants
  let(:shift) { FactoryGirl.build(:shift, :with_restaurant, restaurant: restaurant) }
  let(:shifts) { 31.times.map { FactoryGirl.create(:shift, :without_restaurant) } }
  let(:staffer) { FactoryGirl.create(:staffer) }
  before { mock_sign_in staffer }

  subject { page }

  describe "display pages" do
    
    describe "Shifts#show" do
      before do
        shift.save
        visit shift_path shift
      end      
      
      describe "page contents" do
        it { should have_h3('Shift Details') }
        it { should have_content('Restaurant:') }
        it { should have_content('Start:') }
        it { should have_content('End:') }
        it { should have_content('Urgency:') }
        it { should have_content('Billing:') }
        it { should have_content('Notes:') }
      end
    end

    describe "Shifts#index" do
      before do
        FactoryGirl.create(:shift, :with_restaurant, restaurant: restaurant)
        FactoryGirl.create(:shift, :with_restaurant, restaurant: other_restaurant)
      end 
      # after(:all) { Shift.last(2).each { |s| s.destroy } }
      # let(:shifts) { Shift.last(2) }
      # let(:first_restaurant) { shifts[0].restaurant }
      # let(:second_restaurant) { shifts[1].restaurant }

      describe "from root path" do

        before do 
          visit shifts_path 
          filter_shifts_by_time_inclusively
        end

        let(:first_shift){ 
          FactoryGirl.create(:shift, 
            :with_restaurant, 
            restaurant: restaurant,
            start: Time.zone.local(2012,1,1,11),
            :end => Time.zone.local(2012,1,1,16)
          )
        }
        let(:second_shift){
          FactoryGirl.create(:shift, 
            :with_restaurant, 
            restaurant: other_restaurant,
            start: Time.zone.local(2016,1,1,12),
            :end => Time.zone.local(2016,1,1,16)
          )
        }
        let(:dummy_shift){
          FactoryGirl.create(:shift, 
            :with_restaurant, 
            restaurant: other_restaurant,
            start: Time.zone.local(2014,1,1,13),
            :end => Time.zone.local(2014,1,1,16)
          )
        }

        describe "page contents" do

          it { should have_h1('Shifts')}
          it { should have_link('Create shift') }
          it { should have_content('Restaurant') }
          it { should have_link('Action') }
          it { should have_content(restaurant.mini_contact.name) }
          it { should have_content(other_restaurant.mini_contact.name) }          
        end

        describe "PAGINATION" do
          before do
            shifts
            visit shifts_path
          end

          it { should_not have_content format_start(shifts[30].start) }
        end

        describe "SORTING" do
          before do
            configure_shifts_for_sort_tests
            visit shifts_path
            filter_shifts_by_time_inclusively
            # page.all('div.restaurant').each { |div| div.text }
          end

          it "should order shifts by time by default" do
            expect( page.find('#row_1_col_2').text ).to eq first_shift.table_time
          end

          describe "sorting by restaurant name" do
            describe "ascending" do
              before { click_link('Restaurant') }
              
              it "should sort by restaurants, ascending" do
                expect( page.find('#row_1_col_1').text ).to eq restaurant.name
              end

              describe "descending" do
                before do  
                  click_link('Restaurant') 
                end           

                it "should sort by restaurant name, descending" do
                  expect( page.find('#row_1_col_1').text ).to eq other_restaurant.name
                end  
              end
            end
          end

          describe "sorting by time" do
            describe "descending" do
              before { click_link('Time') }
              
              it "should sort by time, descending" do
                expect( page.find('#row_1_col_2').text ).to eq second_shift.table_time
              end
              
              describe "descending" do
                before { click_link('Time') }            

                it "should sort by time, ascending" do
                  expect( page.find('#row_1_col_2').text ).to eq first_shift.table_time
                end  
              end
            end
          end

          describe "sorting by rider name" do
            describe "ascending" do
              before { click_link('Assigned to') }
              
              it "should sort by riders, ascending" do
                expect( page.find('#row_1_col_4').text ).to eq rider.name
              end

              describe "descending" do
                before { click_link('Assigned to') }            

                it "should sort by rider name, descending" do
                  expect( page.find('#row_1_col_4').text ).to eq '--'
                end  
              end
            end
          end

          describe "sorting by assignment status" do
            describe "ascending" do
              before { click_link('Status') }
              
              it "should sort by statuses, ascending" do
                expect( page.find('#row_1_col_5').text ).to eq AssignmentStatus::CancelledByRestaurant.new.text
              end

              describe "descending" do
                before { click_link('Status') }            

                it "should sort by statuses, descending" do
                  expect( page.find('#row_1_col_5').text ).to eq AssignmentStatus::Unassigned.new.text
                end 
              end
            end
          end
        end

        describe "FILTERING" do
          before do
            configure_shifts_for_sort_tests
            visit shifts_path
            # page.all('div.time').each { |div| puts div.text }
          end
          
          describe "by time" do
            before { filter_shifts_by_time_inclusively } # for default view

            describe "before filtering" do

              it "should include first shift" do
                expect( page.find('#row_1_col_2').text ).to eq first_shift.table_time
              end

              describe "after sorting by time (descending)" do
                before { click_link 'Time' }

                it "should include second shift" do
                  expect( page.find('#row_1_col_2').text ).to eq second_shift.table_time
                end  
              end
            end

            describe "after filtering" do
              before { filter_shifts_by_time_exclusively }

              it "should exclude first shift" do
                expect( page.find('#row_1_col_2').text ).not_to eq first_shift.table_time
              end

              describe "after sorting by time, descending" do
                before { click_link 'Time' }

                it "should exclude second shift" do
                  expect( page.find('#row_1_col_2').text ).not_to eq second_shift.table_time
                end
              end              
            end
          end

          describe "by restaurant" do
            before { filter_shifts_by_time_inclusively } # for default view

            describe "before filtering" do

              describe "after sorting by restaurant (ascending)" do
                before { click_link 'Restaurant' }

                it "should include first shift" do
                  expect( page.find('#row_1_col_1').text ).to eq first_shift.restaurant.name
                end

                describe "after sorting by restaurant (descending)" do
                  before { click_link 'Restaurant' }

                  it "should include second shift" do
                    expect( page.find('#row_1_col_1').text ).to eq second_shift.restaurant.name
                  end                
                end
              end
            end

            describe "after filtering for 2nd rest (and sorting by rest asc)" do
              before do 
                filter_shifts_by_restaurant [ second_shift.restaurant ] 
                click_link 'Restaurant'
              end

              it "should exclude first shift" do
                expect( page.find('#row_1_col_1').text ).not_to eq first_shift.restaurant.name
              end
            end

            describe "after filtering for 1st rest. (& sorting by rest desc)" do
              before do 
                filter_shifts_by_restaurant [ first_shift.restaurant ]
                click_link 'Restaurant'
                click_link 'Restaurant'
              end

              it "should exclude first shift" do
                expect( page.find('#row_1_col_1').text ).not_to eq second_shift.restaurant.name
              end
            end
          end


          describe "by rider" do
            before { filter_shifts_by_time_inclusively } # for default view

            describe "before filtering" do

              describe "after sorting by rider (ascending)" do
                before { click_link 'Assigned to' }

                it "should include first shift" do
                  expect( page.find('#row_1_col_4').text ).to eq first_shift.assignment.rider.name
                end

                describe "after sorting by rider (descending)" do
                  before { click_link 'Assigned to' }

                  it "should include second shift" do
                    expect( page.find('#row_1_col_4').text ).to eq '--'
                  end                
                end
              end
            end  

            describe "after filtering for 2nd rider (and sorting by rider asc)" do
              before do 
                filter_shifts_by_rider [ second_shift.assignment.rider ] 
                click_link 'Assigned to'
              end

              it "should exclude first shift" do
                expect( page.find('#row_1_col_4').text ).not_to eq first_shift.assignment.rider.name
              end
            end

            describe "after filtering for 1st rider (& sorting by rider desc)" do
              before do 
                filter_shifts_by_rider [ first_shift.assignment.rider ]
                click_link 'Assigned to'
                click_link 'Assigned to'
              end
              it "should exclude first shift" do
                expect( page.find('#row_1_col_4').text ).not_to eq '--'
              end
            end
          end

          describe "by status" do
            before do 
              filter_shifts_by_time_inclusively # for default view
              filter_shifts_by_restaurant [ first_shift.restaurant, second_shift.restaurant ]
            end
            
            describe "before filtering" do

              describe "after sorting by status (ascending)" do
                before { click_link 'Status' }

                it "should include first shift" do
                  expect( page.find('#row_1_col_5').text ).to eq first_shift.assignment.status.text
                end

                describe "after sorting by rider (descending)" do
                  before { click_link 'Status' }

                  it "should include second shift" do
                    expect( page.find('#row_1_col_5').text ).to eq second_shift.assignment.status.text
                  end                
                end
              end
            end  

            describe "after filtering for 2nd status (and sorting by status asc)" do
              before do 
                filter_shifts_by_status [ second_shift.assignment.status.text ] 
                click_link 'Status'
              end

              it "should exclude first shift" do
                expect( page.find('#row_1_col_5').text ).not_to eq first_shift.assignment.status.text
              end
            end

            describe "after filtering for 1st status (& sorting by status desc)" do
              before do 
                filter_shifts_by_status [ first_shift.assignment.status.text ]
                click_link 'Status'
                click_link 'Status'
              end
              it "should exclude first shift" do
                expect( page.find('#row_1_col_5').text ).not_to eq second_shift.assignment.status.text
              end
            end
          end

          describe "stickiness" do

            describe "from shift list" do
              before { 
                filter_shifts_by_time_inclusively block_click: true
                filter_shifts_by_rider [first_shift.assignment.rider], block_click: true 
                filter_shifts_by_restaurant [ first_shift.restaurant ], block_click: true
                filter_shifts_by_status [ first_shift.assignment.status.text ], block_click: true
                click_button 'Filter'
              }
              let(:selected_riders){ page.within("#filter_riders"){ all("option[selected]") }.map(&:value) }
              let(:selected_restaurants){ page.within("#filter_restaurants"){ all("option[selected]") }.map(&:value) }
              let(:selected_status){ page.within("#filter_status"){ all("option[selected]") }.map(&:text) }
              let(:selected_start_month){ page.within("#filter_start_month"){ find("option[selected]") }.value }
              let(:selected_end_month){ page.within("#filter_end_month"){ find("option[selected]") }.value }

              describe "from batch assign action" do
                
                describe "without obstacles" do
                  before { batch_assign_first_shift }

                  it "should retain original filter settings" do
                    check_original_filters_retained
                  end 
                end

                describe "with conflict" do
                  before do 
                    FactoryGirl.create( :conflict, :with_rider, rider: first_shift.rider, start: first_shift.start, :end => first_shift.end )
                    batch_assign_first_shift
                  end

                  describe "overriding" do
                    before do
                      choose "decisions_0_Override"
                      click_button 'Submit'
                    end
                    
                    it "should retain original filter settings" do
                      check_original_filters_retained
                    end                   
                  end

                  describe "accepting" do
                    before do
                      choose "decisions_0_Accept"
                      click_button 'Submit'
                      page.within("#assignments_requiring_reassignment_0") { find("#wrapped_assignments_fresh__assignment_rider_id").select other_rider.name }
                      click_button 'Save changes'
                    end
                    
                    it "should retain original filter settings" do
                      check_original_filters_retained
                    end                   
                  end
                end
              end # "from batch assign action"

              describe "from uniform assign action" do
                before do 
                  page.within("#row_1"){ check "ids[]" }
                  click_button 'Uniform Assign', match: :first
                  select first_shift.rider.name, from: 'assignment[rider_id]'
                  click_button 'Save changes'
                end

                it "should retain original filter settings" do
                  check_original_filters_retained
                end              
              end # "from batch assign action"              
            end # "from shift list"

            describe "from shift grid" do
              load_batch
              before do
                batch.each(&:save)
                visit shift_grid_path
                filter_grid_for_jan_2014
                select_batch_assign_shifts_from_grid
                click_button 'Batch Assign'
                click_button 'Save changes'
              end

              it "should retain original filter settings" do
                expect(page.find('#filter_start').value).to eq 'January 6, 2014'
              end
            end # "from shift grid"
          end # "stickiness"
        end
      end

      describe "from restaurant path" do
        before { visit restaurant_shifts_path(restaurant) }
        it { should have_content(restaurant.mini_contact.name) }
        it { should_not have_content(other_restaurant.mini_contact.name) }
      end
    end

    describe "Shifts#points_review" do
      load_batch
      before do 
        batch.each_with_index{ |shift, i| shift.assignment.update(notes: "Some notes about assignment #{i}") } 
        visit review_points_shifts_path
        filter_shifts_by_time_inclusively
      end
      
      it "should have correct contents" do
        batch.each_with_index{ |shift, i| check_point_review_row shift, i }
      end
    end
  end

  describe "form pages" do
    
    describe "Shifts#new" do
      
      let(:submit) { 'Create shift' }
      let(:models) { [ Shift ] }
      let!(:old_counts) { count_models models }

      describe "from root path" do
        before { visit new_shift_path }

        it "should have correct form fields" do
          check_shift_form_contents 'root'
        end

        describe "form submission" do

          describe "with invalid input" do
            before { make_invalid_shift_submission }

            it { should have_an_error_message }
          end

          describe "with valid input" do
            before { make_valid_shift_submission }

            describe "after submission" do
              let(:new_counts){ count_models models }
              it "should create a new shift" do
                expect( model_counts_incremented? old_counts, new_counts, 1).to eq true 
              end
              it "should give the shift a blank assignment" do
                expect( shift.assignment.nil? ).to eq false
              end
              it { should have_success_message('Shift created') }
              it { should have_h1('Shifts') }                
            end
          end
        end
      end

      describe "from restaurant path" do
        before { visit new_restaurant_shift_path(restaurant) }

        it { should_not have_label('Restaurant') }
      end
    end

    describe "Shifts#edit" do
      
      let(:submit) { 'Save changes' }

      describe "from shifts path" do

        before do 
          shift.save
          visit edit_shift_path(shift) 
        end
        
        it "should have correct form fields" do
          check_shift_form_contents 'root'
        end 

        describe "with invalid input" do
          before { make_invalid_shift_submission }

          it { should have_an_error_message }
        end

        describe "with valid input" do
          before { make_valid_shift_submission }

          it { should have_success_message('Shift updated') }
          it { should have_h1('Shifts') }
        end
      end

      describe "from restaurants path" do
        it { should_not have_label('Restaurant') }
      end
    end
  end

  describe "BATCH REQUESTS" do
    before { restaurant }
    
    let!(:old_count){ Shift.count }
    load_batch

    subject { page }
    
    describe "BATCH CREATE" do
      
      describe "clone page" do 
        before { visit '/shift/clone_new' }

        describe "page contents" do
          
          it { should have_h1('Batch Create Shifts -- Base Shift') }
          it "should have correct shift form labels" do 
            check_shift_form_contents 'root' 
          end
          it "should have correct batch shift selects" do
            check_batch_shift_selects
          end
          it { should have_label 'Number of Clones to Make:' }
          it { should have_select 'num_shifts' }
        end
        
        describe "batch create page" do
          before { make_base_shift }

          describe "page contents" do
            
            it "should have correct uri" do 
              expect(current_path).to eq "/shift/batch_new"
              expect(URI.parse(current_url).to_s).to include("?utf8=%E2%9C%93&shifts[][id]=&shifts[][restaurant_id]=#{restaurant.id}")
            end
            
            it { should have_h1 'Batch Create Shifts' }
            it { should have_content(restaurant.name) }

            it "should have correct start dates" do
              expect(page.all("#shifts__start_day")[0].find('option[selected]').text).to eq batch[0].start.day.to_s
              expect(page.all("#shifts__start_day")[1].find('option[selected]').text).to eq batch[1].start.day.to_s
              expect(page.all("#shifts__start_day")[2].find('option[selected]').text).to eq batch[2].start.day.to_s
            end
          end

          describe "executing batch create" do
            before do 
              click_button 'Save changes' 
            end

            it "should create 3 new shifts" do
              expect(Shift.count).to eq old_count + 3
            end
            it "should have correct URI" do 
              expect(current_path).to include '/shifts'
            end

            describe "shift listings" do
              before { filter_shifts_by_time_inclusively }
              
              it "should show new shifts" do
                expect(page.find("#row_1_col_2").text).to eq batch[0].table_time
                expect(page.find("#row_2_col_2").text).to eq batch[1].table_time
                expect(page.find("#row_3_col_2").text).to eq batch[2].table_time
              end
            end
          end     
        end 
      end
    end  

    describe "BATCH EDIT" do
      before { batch.each(&:save) }

      describe "from shifts index" do
        before do 
          visit shifts_path
          filter_shifts_by_time_inclusively 
        end

        describe "page contents" do
          it { should have_button 'Batch Edit' }
          it { should have_button 'Batch Assign' }
          it "should have correct form action" do
            expect(page.find("form.batch")['action']).to eq '/shift/batch_edit'
          end
          it "should have correct checkbox id values" do
            expect( page.within( "#row_1" ) { find("#ids_")['value'] } ).to eq batch[0].id.to_s
            expect( page.within( "#row_2" ) { find("#ids_")['value'] } ).to eq batch[1].id.to_s
            expect( page.within( "#row_3" ) { find("#ids_")['value'] } ).to eq batch[2].id.to_s
          end          
        end

        describe "batch edit shift page" do
          before do
            page.within("#row_1"){ find("#ids_").set true }
            page.within("#row_2"){ find("#ids_").set true }
            page.within("#row_3"){ find("#ids_").set true } 
            click_button 'Batch Edit', match: :first
          end

          describe "page contents" do 
            it "should have correct URI" do 
              expect(current_path).to eq "/shift/batch_edit"
              expect(URI.parse(current_url).to_s).to include("&ids[]=#{batch[0].id}&ids[]=#{batch[1].id}&ids[]=#{batch[2].id}&commit=Batch+Edit")
            end
            
            it { should have_h1 'Batch Edit Shifts' }
            it { should have_content(restaurant.name) }

            it "should have correct start dates" do
              expect(page.all("#shifts__start_day")[0].find('option[selected]').text).to eq batch[0].start.day.to_s
              expect(page.all("#shifts__start_day")[1].find('option[selected]').text).to eq batch[1].start.day.to_s
              expect(page.all("#shifts__start_day")[2].find('option[selected]').text).to eq batch[2].start.day.to_s
            end

            describe "executing batch edit" do
              before do  
                page.all("#shifts__start_hour")[0].select '6 AM'
                page.all("#shifts__start_hour")[1].select '7 AM'
                page.all("#shifts__start_hour")[2].select '8 AM'
                click_button 'Save changes'
              end

              describe "after editing" do

                it "should have correct URI" do
                  expect(current_path).to eq "/shifts/"
                end

                describe "page contents" do
                  before { filter_shifts_by_time_inclusively }

                  it "should show new values of edited shifts" do
                    expect(page.find("#row_1_col_2").text).to include '6:00AM'
                    expect(page.find("#row_2_col_2").text).to include '7:00AM'
                    expect(page.find("#row_3_col_2").text).to include '8:00AM'
                  end
                end
              end
            end
          end
        end
      end 
    end

    describe "BATCH DELETE" do

      before{ batch.each(&:save) }

      let!(:shift_count){ Shift.count }
      
      before do 
        visit shifts_path
        filter_shifts_by_time_inclusively
        page.within("#row_1"){ find("#ids_").set true }
        page.within("#row_2"){ find("#ids_").set true }
        click_button 'Batch Delete', match: :first
      end

      it "should delete 3 shifts" do
        expect(Shift.count).to eq shift_count - 2
      end
    end

    describe "BATCH ASSIGN" do
      before do
        # initialize rider & shifts, assign shifts to rider
        other_rider
        batch.each(&:save)
        batch.each { |s| s.assignment.update(rider_id: rider.id, status: :confirmed) }
      end

      describe "from SHIFTS INDEX" do
        before do
          # select shifts for batch assignment
          visit shifts_path
          filter_shifts_by_time_inclusively
          page.within("#row_1"){ find("#ids_").set true }
          page.within("#row_2"){ find("#ids_").set true }
          page.within("#row_3"){ find("#ids_").set true }        
        end

        describe "with STANDARD batch edit" do
          before { click_button 'Batch Assign', match: :first }
          
          describe "batch edit assignment page" do 
            it "should have correct URI" do 
              check_batch_assign_uri
            end
            
            it { should have_h1 'Batch Assign Shifts' }
            it { should have_content(restaurant.name) }

            it "should have correct select values" do
              check_batch_assign_select_values rider, 'Confirmed'
            end
          end

          describe "EXECUTING batch assignment" do

            describe "WITHOUT OBSTACLES" do
              before { assign_batch_to other_rider, 'Proposed' }

              describe "after editing" do
                
                it "should redirect to the correct page" do
                  expect(current_path).to eq "/shifts/"
                end

                describe "index page" do
                  before { filter_shifts_by_time_inclusively }

                  it "should show new values of edited shifts" do
                    check_reassigned_shift_values other_rider, 'Proposed'
                  end
                end            
              end # "after editing"              
            end # "WITHOUT OBSTACLES"  

            describe "WITH CONFLICT" do
              load_conflicts
              before do
                conflicts[0].save
                assign_batch_to other_rider, 'Proposed'
              end
                
              describe "Resolve Obstacles page" do

                describe "CONTENTS" do
                  
                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should correctly list Assignments With Conflicts" do
                    check_assignments_with_conflicts_list [0], [0]
                  end

                  it "should not list Assignments With Double Bookings" do
                    expect(page).not_to have_selector("#assignments_with_double_bookings")
                  end

                  it "should correctly list Assignments Without Obstacles" do
                    check_without_obstacles_list [0,1], [1,2]
                  end
                end # "CONTENTS"

                describe "OVERRIDING" do
                  before do
                    choose "decisions_0_Override"
                    click_button 'Submit'
                  end

                  describe "after submission" do
                    before { filter_shifts_by_time_inclusively }

                    it "should redirect to the index page" do
                      expect(current_path).to eq "/shifts/"
                      expect(page).to have_h1 'Shifts'
                    end

                    it "should show new values for reassigned shifts" do
                      check_reassigned_shift_values other_rider, 'Proposed'
                    end
                  end # "after submission (on shifts index)"
                end # "OVERRIDING"

                describe "ACCEPTING" do
                  load_free_rider
                  before do
                    choose 'decisions_0_Accept'
                    click_button 'Submit'
                  end

                  describe "after submission" do

                    describe "batch reassign page" do

                      it "should be the batch reassign page" do
                        expect(current_path).to eq '/assignment/resolve_obstacles'
                        expect(page).to have_h1 'Batch Reassign Shifts'                         
                      end

                      it "should correctly list Assignements Requiring Reassignment" do
                        check_reassign_single_shift_list other_rider, 'Proposed', 0
                      end

                      it "should not list Assignments With Double Bookings" do
                        expect(page).not_to have_selector("#assignments_with_double_bookings")
                      end

                      it "should correctly list Assignments Without Obstacles" do
                        check_without_obstacles_list [0,1], [1,2]
                      end                        
                    end

                    describe "executing REASSIGNMENT TO FREE RIDER" do
                      before { reassign_single_shift_to free_rider, 'Proposed' }

                      describe "after submission" do
                        
                        it "should redirect to the correct page" do
                          expect(current_path).to eq "/shifts/"
                          expect(page).to have_h1 'Shifts'
                        end

                        describe "index page" do
                          before { filter_shifts_by_time_inclusively }

                          it "shoud show new values for reassigned shifts" do
                            check_reassigned_shift_values_after_accepting_obstacle other_rider, free_rider, 'Proposed'
                          end
                        end #"index page"
                      end # "after submission"
                    end # "executing REASSIGNMENT TO FREE RIDER"

                    describe "executing REASSIGNMENT TO RIDER WITH CONFLICT" do
                      before{ click_button 'Save changes' }

                      it "should redirect to resolve obstacles page" do
                        expect(current_path).to eq "/assignment/batch_reassign"
                        expect(page).to have_h1 'Resolve Scheduling Obstacles'
                      end
                    end #"executing REASSIGNMENT TO RIDER WITH CONFLICT"

                    describe "executing REASSIGNMENT TO RIDER WITH DOUBLE BOOKING" do
                      load_double_bookings
                      before do
                        double_bookings[0].save
                        double_bookings[0].assign_to free_rider
                        reassign_single_shift_to free_rider, 'Confirmed'
                      end

                      it "should redirect to resolve obstacles page" do
                        expect(current_path).to eq "/assignment/batch_reassign"
                        expect(page).to have_h1 'Resolve Scheduling Obstacles'
                      end
                    end #"executing REASSIGNMENT TO RIDER WITH CONFLICT"
                  end # "after submission"
                end # "ACCEPTING"
              end # "Resove Obstacles Page"

            end # "WITH CONFLICT"

            describe "WITH 2 CONFLICTS" do
              load_conflicts
              before do
                conflicts[0..1].each(&:save)
                assign_batch_to other_rider, 'Proposed'
              end

              describe "Resolve Obstacles page" do

                describe "CONTENTS" do
                  
                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should correctly list Assignments With Conflicts" do
                    check_assignments_with_conflicts_list [0,1], [0,1]
                  end

                  it "should not list Assignments With Double Bookings" do
                    expect(page).not_to have_selector("#assignments_with_double_bookings")
                  end

                  it "should correctly list Assignments Without Obstacles" do
                    check_without_obstacles_list [0], [2]
                  end
                end # "CONTENTS"
              end # "Resolve Obstacles page"
            end # "WITH 2 CONFLICTS"

            describe "WITH 3 CONFLICTS" do
              load_conflicts
              before do
                conflicts.each(&:save)
                assign_batch_to other_rider, 'Proposed'
              end

              describe "Resolve Obstacles page" do

                describe "CONTENTS" do
                  
                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should correctly list Assignments With Conflicts" do
                    check_assignments_with_conflicts_list [0,1,2], [0,1,2]
                  end

                  it "should not list Assignments With Double Bookings" do
                    expect(page).not_to have_selector("#assignments_with_double_bookings")
                  end

                  it "should not list Assignments Without Obstacles" do
                    expect(page).not_to have_selector("#assignments_without_obstacles")
                  end
                end # "CONTENTS"
              end # "Resolve Obstacles page"
            end # "WITH 3 CONFLICTS"

            describe "WITH DOUBLE BOOKING" do
              load_double_bookings
              before do
                double_bookings[0].save
                double_bookings[0].assign_to other_rider
                assign_batch_to other_rider, 'Proposed'
              end

              describe "Resolve Obstacles page" do
                
                describe "CONTENTS" do
                  
                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should not list Assignments With Conflicts" do
                    expect(page).not_to have_selector("#assignments_with_conflicts")
                  end

                  it "should correctly list Assignments With Double Bookings" do
                    check_assignments_with_double_booking_list [0], [0]
                  end

                  it "should correctly list Assignments Without Obstacles" do
                    check_without_obstacles_list [0,1], [1,2]
                  end
                end # "CONTENTS"

                describe "OVERRIDING" do
                  before do
                    choose "decisions_0_Override"
                    click_button 'Submit'
                  end

                  describe "after submission" do
                    
                    it "should redirect to the correct page" do
                      expect(current_path).to eq "/shifts/"
                      expect(page).to have_h1 'Shifts'
                    end

                    describe "index page" do
                      before { filter_shifts_by_time_inclusively }

                      it "shoud show new values for reassigned shifts" do
                        check_reassigned_shift_values other_rider, 'Proposed'
                      end
                    end # "index page"
                  end # "after submission"
                end # "OVERRIDING"

                describe "ACCEPTING" do
                  load_free_rider
                  before do
                    choose 'decisions_0_Accept'
                    click_button 'Submit'
                  end

                  describe "after submission" do

                    describe "batch reassign page" do

                      it "should redirect to the correct page" do
                        expect(current_path).to eq '/assignment/resolve_obstacles'
                        expect(page).to have_h1 'Batch Reassign Shifts'                         
                      end

                      it "should correctly list Assignments Requiring Reassignment" do
                        check_reassign_single_shift_list other_rider, 'Proposed', 0
                      end

                      it "should not list Assignments With Double Bookings" do
                        expect(page).not_to have_selector("#assignments_with_double_bookings")
                      end

                      it "should correctly list Assignemnts Without Obstacles" do
                        check_without_obstacles_list [0,1], [1,2]
                      end                        
                    end

                    describe "executing REASSIGNMENT TO FREE RIDER" do
                      before { 
                        reassign_single_shift_to free_rider, 'Proposed' 
                      }

                      describe "after submission" do
                        
                        it "should redirect to the correct page" do
                          expect(current_path).to eq "/shifts/"
                          expect(page).to have_h1 'Shifts'
                        end

                        describe "index page" do
                          before { filter_shifts_by_time_inclusively }

                          it "should show new values for reassigned shifts" do
                            check_reassigned_shift_values_after_accepting_obstacle other_rider, free_rider, 'Proposed'
                          end
                        end #"index page"
                      end # "after submission"
                    end # "executing REASSIGNMENT TO FREE RIDER"
                  end # "after submission"
                end # "ACCEPTING"
              end # "Resolve Obstacles page"
            end # "WITH DOUBLE BOOKING"

            describe "WITH 2 DOUBLE BOOKINGS" do
              load_double_bookings
              before do
                double_bookings[0..1].each do |shift|
                  shift.save
                  shift.assign_to other_rider
                end
                assign_batch_to other_rider, 'Proposed'
              end

              describe "Resolve Obstacles page" do

                describe "CONTENTS" do
                  
                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should not list Assignments With Conflicts" do
                    expect(page).not_to have_selector("#assignments_with_conflicts")
                  end

                  it "should correctly list Assignments With Double Bookings" do
                    check_assignments_with_double_booking_list [0,1], [0,1]
                  end

                  it "should correctly list Assignments Without Obstacles" do
                    check_without_obstacles_list [0], [2]
                  end
                end # "CONTENTS"
              end # "Resolve Obstacles page"
            end # "WITH 2 DOUBLE BOOKINGS"

            describe "WITH 3 DOUBLE BOOKINGS" do
              load_double_bookings
              before do
                double_bookings.each do |shift|
                  shift.save
                  shift.assign_to other_rider
                end
                assign_batch_to other_rider, 'Proposed'
              end

              describe "Resolve Obstacles page" do

                describe "CONTENTS" do
                  
                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should not list Assignments With Conflicts" do
                    expect(page).not_to have_selector("#assignments_with_conflicts")
                  end

                  it "should correctly list Assignments With Double Bookings" do
                    check_assignments_with_double_booking_list [0,1,2], [0,1,2]
                  end

                  it "should not list Assignments Without Obstacles" do
                    expect(page).not_to have_selector("#assignments_without_obstacles")
                  end
                end # "CONTENTS"
              end # "Resolve Obstacles page"
            end # "WITH 2 DOUBLE BOOKINGS"

            describe "WITH CONFLICT AND DOUBLE BOOKING" do
              load_conflicts
              load_double_bookings
              before do
                conflicts[0].save
                double_bookings[1].save
                double_bookings[1].assign_to other_rider
                assign_batch_to other_rider, 'Proposed'
              end

              describe "Resolve Obstacles Page" do
                
                describe "CONTENTS" do

                  it "should be the Resolve Obstacles page" do
                    expect(current_path).to eq "/assignment/batch_edit"
                    expect(page).to have_h1 'Resolve Scheduling Obstacles'
                  end

                  it "should correctly list Assignments With Conflicts" do
                    check_assignments_with_conflicts_list [0], [0]
                  end

                  it "should correctly list Assignments With Double Bookings" do
                    check_assignments_with_double_booking_list [0], [1]
                  end

                  it "should correctly list Assignments Without Obstacles" do
                    check_without_obstacles_list [0], [2]
                  end
                end # "CONTENTS"

                describe "OVERRIDING BOTH" do
                  before do
                    choose "decisions_0_Override"
                    choose "decisions_1_Override"
                    click_button 'Submit'                    
                  end

                  describe "after submission" do
                    before { filter_shifts_by_time_inclusively }

                    it "should redirect to the index page" do
                      expect(current_path).to eq "/shifts/"
                      expect(page).to have_h1 'Shifts'
                    end

                    it "should show new values for reassigned shifts" do
                      check_reassigned_shift_values other_rider, 'Proposed'
                    end
                  end # "after submission (on shifts index)"
                end # "OVERRIDING BOTH"

                describe "OVERRIDING CONFLICT / ACCEPTING DOUBLE BOOKING" do
                  before do
                    choose "decisions_0_Override"
                    choose "decisions_1_Accept"
                    click_button 'Submit' 
                  end

                  describe "after submission" do
                    
                    describe "batch reassign page" do

                      it "should be the batch reassign page" do
                        expect(current_path).to eq '/assignment/resolve_obstacles'
                        expect(page).to have_h1 'Batch Reassign Shifts'                         
                      end

                      it "should correctly list Assignments Requiring Reassignment" do
                        check_reassign_single_shift_list other_rider, 'Proposed', 1
                      end

                      it "should correctly list Assignments Without Obstacles" do
                        check_without_obstacles_list [0,1], [2,0]
                      end                        
                    end
                  end # "after submission"
                end # "OVERRIDING CONFLICT / ACCEPTING DOUBLE BOOKING"

                describe "ACCEPTING CONFLICT / OVERRIDING DOUBLE BOOKING" do
                  before do
                    choose "decisions_0_Accept"
                    choose "decisions_1_Override"
                    click_button 'Submit' 
                  end

                  describe "after submission" do
                    
                    describe "batch reassign page" do

                      it "should be the batch reassign page" do
                        expect(current_path).to eq '/assignment/resolve_obstacles'
                        expect(page).to have_h1 'Batch Reassign Shifts'                         
                      end

                      it "should correctly list Assignments Requiring Reassignment" do
                        check_reassign_single_shift_list other_rider, 'Proposed', 0
                      end

                      it "should correctly list Assignments Without Obstacles" do
                        check_without_obstacles_list [0,1], [2,1]
                      end                        
                    end # "batch reassign page"
                  end # "after submission"
                end # "OVERRIDING CONFLICT / ACCEPTING DOUBLE BOOKING"
              end # "Resolve Obstacles Page"
            end # "WITH CONFLICT AND DOUBLE BOOKING"
          end # "EXECUTING batch assignment"
        end # "with STANDARD batch edit"

        describe "with UNIFORM batch edit" do
          before { click_button 'Uniform Assign', match: :first }

          describe "Uniform Assign Shifts page" do
            
            it "should have correct URI and Header" do
              check_uniform_assign_uri
              expect(page).to have_h1 "Uniform Assign Shifts"
            end

            it "should list Shifts correctly" do
              check_uniform_assign_shift_list rider, 'Confirmed'
            end

            it "should have correct form values" do
              check_uniform_assign_select_values
            end
          end

          describe "EXECUTING batch assignment" do

            describe "WITHOUT OBSTACLES" do
              before { uniform_assign_batch_to other_rider, 'Cancelled (Rider)' }

              describe "after editing" do

                it "should redirect to the correct page" do
                  expect(current_path).to eq "/shifts/"
                  expect(page).to have_h1 'Shifts'
                end

                describe "index page" do
                  before { filter_shifts_by_time_inclusively }

                  it "should show new values for re-assigned shifts" do
                    check_reassigned_shift_values other_rider, 'Cancelled (Rider)'
                  end
                end # "index page"
              end # "after editing"               
            end # "WITHOUT OBSTACLES"

            describe "WITH CONFLICT" do
              load_conflicts
              before do
                conflicts[0].save
                uniform_assign_batch_to other_rider, 'Proposed'
              end
                                  
              it "should redirect to the Resolve Obstacles page" do
                expect(current_path).to eq "/assignment/batch_edit_uniform"
                expect(page).to have_h1 'Resolve Scheduling Obstacles'
              end
            end # "WITH CONFLICT"

            describe "WITH DOUBLE BOOKING" do
              load_double_bookings
              before do
                double_bookings[0].save
                double_bookings[0].assign_to other_rider
                uniform_assign_batch_to other_rider, 'Proposed'
              end
                  
              it "should be the Resolve Obstacles page" do
                expect(current_path).to eq "/assignment/batch_edit_uniform"
                expect(page).to have_h1 'Resolve Scheduling Obstacles'
              end
            end # "WITH DOUBLE BOOKING"
          end # "EXECUTING batch assignment"
        end # "Uniform Assign Shifts page"
      end # "with UNIFORM batch edit"

      describe "from GRID" do
        before do 
          restaurant.mini_contact.update(name: 'A'*10)
          visit shift_grid_path 
          filter_grid_for_jan_2014
        end

        describe "page contents" do

          describe "batch edit form" do

            it { should have_button 'Batch Assign' }
            it "should have correct form action" do
              expect(page.find("form.batch")['action']).to eq '/shift/batch_edit'
            end              
          end

          describe "grid rows" do

            it "should have correct cells in first row" do
              expect(page.find("#row_1_col_1").text).to eq 'A'*10
              expect(page.find("#row_1_col_2").text).to eq rider.short_name + " [c]"
              expect(page.find("#row_1_col_4").text).to eq rider.short_name + " [c]"
              expect(page.find("#row_1_col_6").text).to eq rider.short_name + " [c]"
            end              
          end
        end

        describe "STANDARD batch assignment" do
          before do
            select_batch_assign_shifts_from_grid
            click_button 'Batch Assign'
          end

          describe "batch assign page" do
            it "should have correct URI" do
              check_batch_assign_uri
            end

            it "should have correct assignment values" do
              check_batch_assign_select_values rider, 'Confirmed'
            end            
          end

          describe "executing batch assignment" do
            before { assign_batch_to rider, 'Proposed' }

            describe "after editing" do

              it "should redirect to the correct page" do
                expect(current_path).to eq "/grid/shifts"
              end

              describe "page contents" do
                before { filter_grid_for_jan_2014 }

                it "should have new assignment values" do
                  check_reassigned_shift_values_in_grid other_rider, '[p]'
                end
              end
            end
          end
        end

        describe "UNIFORM batch assignment" do
          before do 
            select_batch_assign_shifts_from_grid
            click_button 'Uniform Assign'
          end

          describe "uniform assign page" do
            
            it "should have correct uri" do
              check_uniform_assign_uri
            end

            it { should have_h1 'Uniform Assign Shifts' }
            it { should have_content restaurant.name }

            it "should have correct form values" do
              check_uniform_assign_select_values
            end
          end

          describe "executing batch edit" do
            before { uniform_assign_batch_to other_rider, 'Cancelled (Rider)' }

            describe "after editing" do
              it "should redirect to the correct page" do
                expect(current_path).to eq "/grid/shifts"
              end

              describe "index page" do
                before { filter_grid_for_jan_2014 }

                it "should show new values for re-assigned shifts" do
                  check_reassigned_shift_values_in_grid other_rider, '[xf]'
                end
              end
            end
          end
        end
      end 
    end  

    describe "CLONE LAST WEEK" do
      load_this_week_shifts
      let!(:count){ Shift.count }

      describe "building week preview WITH ALL RESTAURANTS" do
        before do  
          visit '/shift/build_clone_week_preview'
          fill_in 'week_start', with: 'January 6, 2014'
          click_button 'Submit'
        end

        it "should forward to the Clone Week Preview page" do
          expect(current_path).to eq '/shift/preview_clone_week'
          expect(page).to have_h1 'Preview Clone Week'
        end

        describe "Clone Week Preview page" do
          
          it "should have correct fields" do
            check_clone_week_fields [restaurants[0], restaurants[1]], [ 6, 6 ], this_week_shifts
            expect(page).not_to have_h3 "#{restaurants[2].name}"
          end

          describe "CLONING shifts" do
            load_next_week_shifts
            
            describe "WITHOUT EDITS" do
              before { click_button 'Submit' }

              it "should create 14 new shifts" do
                expect(Shift.count).to eq count + 14
              end

              it "should format shifts correctly" do
                check_cloned_shift_values Shift.last(14), next_week_shifts
              end

              it "should redirect to shifts index" do
                expect(current_path).to eq '/shifts/'
              end
            end # "WITHOUT EDITS"

            describe "WITH EDITS", js: true do
              
              describe "REMOVING SHIFTS" do
                before do 
                  page.find('#remove_restaurant_1_shift_6').click
                  page.find('#remove_restaurant_1_shift_0').click
                  click_button 'Submit'
                end

                it "should create 13 new shifts" do
                  expect( Shift.count ).to eq count + 12
                end

                it "should format shifts correctly" do
                  check_cloned_shift_values Shift.last(12), expected_new_shifts(:remove)
                end
              end  # REMOVING SHIFTS"

              describe "ADDING SHIFTS" do
                before do 
                  page.find('#add_shift_restaurant_1').click 
                  page.find('#add_shift_restaurant_1').click
                end

                it "should display edit fields with correct contents" do
                  expect(page.find('#restaurant_1 #shift_7 #restaurant_shifts__shifts__start').value).to eq 'Jan 13, 2014 - 12:00 PM'
                  expect(page.find('#restaurant_1 #shift_7 #restaurant_shifts__shifts__end').value).to eq 'Jan 13, 2014 - 6:00 PM'
                  expect(page.find('#restaurant_1 #shift_8 #restaurant_shifts__shifts__start').value).to eq 'Jan 13, 2014 - 12:00 PM'
                  expect(page.find('#restaurant_1 #shift_8 #restaurant_shifts__shifts__end').value).to eq 'Jan 13, 2014 - 6:00 PM'
                end

                describe "WITH NO ERRORS" do
                  before { click_button 'Submit' }
                  let!(:last_16_shifts){ Shift.last(16) }

                  it "should create 16 new shifts with correct values" do
                    # expect( Shift.count ).to eq count + 16
                    check_cloned_shift_values last_16_shifts, expected_new_shifts(:add)
                  end
                end #"WITH NO ERRORS"
              end # "ADDING SHIFTS"

              describe "EDITING SHIFTS" do

                describe "CLICKING edit" do
                  before do 
                    page.find('#edit_restaurant_0_shift_0').click
                    page.find('#edit_restaurant_0_shift_1').click
                  end

                  it "should display edit fields with correct contents" do
                    expect(page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__start').value).to eq next_week_shifts[0].formal_start_time
                    expect(page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__end').value).to eq next_week_shifts[0].formal_end_time
                    expect(page.find('#restaurant_0 #shift_1 #restaurant_shifts__shifts__start').value).to eq next_week_shifts[1].formal_start_time
                    expect(page.find('#restaurant_0 #shift_1 #restaurant_shifts__shifts__end').value).to eq next_week_shifts[1].formal_end_time
                  end

                  describe "saving WITH NO ERRORS" do
                    before do
                      page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__start').set 'Jan 13, 2014 - 10:00 AM'
                      page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__end').set 'Jan 13, 2014 - 4:00 PM'
                      
                      page.find('#restaurant_0 #shift_1 #restaurant_shifts__shifts__start').set 'Jan 14, 2014 - 10:00 AM'
                      page.find('#restaurant_0 #shift_1 #restaurant_shifts__shifts__end').set 'Jan 14, 2014 - 4:00 PM'
                      
                      click_button 'Submit'                
                    end
                    
                    it "should create 14 shifts with correct values" do
                      expect(Shift.count).to eq count + 14
                      check_cloned_shift_values Shift.last(14), expected_new_shifts(:edit)
                    end 
                  end # "saving WITH NO ERRORS"

                  describe "saving with START-BEFORE-END ERROR" do
                    before do 
                      page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__start').set 'Jan 13, 2014 - 9:00 PM'
                      click_button 'Submit'
                    end

                    it "should have an error message" do
                      expect(page).to have_an_error_message
                    end
                  end # "saving with START-BEFORE-END ERROR"

                  describe "saving with SHIFT-TOO-EARLY ERROR" do
                    before do 
                      page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__start').set 'Jan 1, 2014 - 9:00 PM'
                      click_button 'Submit'
                    end

                    it "should have an error message" do
                      expect(page).to have_an_error_message
                    end
                  end # "saving with SHIFT-TOO-EARLY ERROR"   

                  describe "saving with SHIFT-TOO-LATE ERROR" do
                    before do 
                      page.find('#restaurant_0 #shift_0 #restaurant_shifts__shifts__start').set 'Jan 1, 2015 - 9:00 PM'
                      click_button 'Submit'
                    end

                    it "should have an error message" do
                      expect(page).to have_an_error_message
                    end
                  end # "saving with SHIFT-TOO-LATE ERROR"            
                end # "CLICKING edit"
              end # "EDITING SHIFTS"
            end # "WITH EDITS"
          end # "CLONING shifts"
        end # "Clone Week Preview page"
      end # "building week preview"
    end # "CLONE LAST WEEK"
  end
end



