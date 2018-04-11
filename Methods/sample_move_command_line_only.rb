class StudySample < ActiveRecord::Base ; end

class Asset
  has_many :submitted_assets
  has_many :orders, :through => :submitted_assets, :as => :asset
end

module Submission::QuotaBehaviour
  def book_quota_available_for_request_types!
    # Do not, whatever happens, mess with quota!
  end
end

def move_samples(samples,study_to_move_samples_from,study_to_move_samples_to,user_login,rt_ticket,mode)
  puts "running in test unless mode = run" unless mode == "run"
  user = User.find_by_login(user_login) or raise StandardError, "Cannot find the user #{user_login.inspect}"
  submissions = Set.new
  puts "samples: #{samples.size}\nfrom: #{study_to_move_samples_from}\nto: #{study_to_move_samples_to}\nrequested by: #{user_login}\nvia ticket: #{rt_ticket}\nmode: #{mode}\n"
  ActiveRecord::Base.transaction do
    puts "UPDATING SAMPLES AND ALIQUOTS"
    samples.each do |sample_name|
      puts "#{sample_name}"
      study_from, study_to, sample = Study.find(study_to_move_samples_from), Study.find(study_to_move_samples_to), Sample.find_by_name(sample_name)
      # sample = Sample.find_by_id(sample_name) if sample == nil
      comment_text = "Sample #{sample.id} moved from #{study_to_move_samples_from} to #{study_to_move_samples_to} requested via RT ticket #{rt_ticket} using sample_move_command_line_only.rb"
      comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Sample move #{rt_ticket}") }

      puts "Moving sample #{sample.id} #{sample_name}"

      [ sample, study_from, study_to ].map(&comment_on)

      sample.aliquots.find_each(:conditions => { :study_id => study_to_move_samples_from }) do |aliquot|
        aliquot.study_id = study_to_move_samples_to
        aliquot.save!

        aliquot.receptacle.tap do |asset|
          puts "\tMoving #{asset.sti_type} #{asset.id}"

          comment_on.call(asset)

          requests = asset.requests.all(:conditions => { :initial_study_id => study_to_move_samples_from })
          requests.map(&comment_on)
          requests.map(&:submission).compact.map(&submissions.method(:<<))

          asset.asset_groups.find_each(:conditions => { :study_id => study_to_move_samples_from }) do |asset_group|
            puts "ASSET GROUP >> #{asset_group.name}"
            asset_group.update_attributes!(:study_id => study_to_move_samples_to)
          end
        end
      end
      puts "Finished saving asset_group"
      
      sample.study_samples.find_each do |study_sample|
        begin
          study_sample.update_attributes!(:study_id => study_to_move_samples_to)
        rescue ActiveRecord::RecordInvalid => invalid
          study_links = StudySample.find(:all, :conditions => ['sample_id = ? AND study_id = ?',study_sample.sample_id,study_to_move_samples_from])
          study_links.each do |link|
            puts "Sample already associated with #{study_to_move_samples_to} => Destroying #{link.inspect}\n"
            link.destroy
          end
        end
      end
      puts "Finished saving study_sample"

      puts comment_text
    end
  
  
    sub_ids = submissions.map(&:id)
    c = sub_ids.size
    submissions = []
  
       
    puts "Updating all of the submissions (#{sub_ids.size}) encountered as part of the sample moves ..."
    puts "sub_ids: #{sub_ids.inspect}"
      sub_ids.each do |sub_id|
        puts "#{c}: #{sub_id}"
        ActiveRecord::Base.transaction do
        submission = Submission.find_by_id sub_id
        next unless submission.ready?
        # raise RuntimeError, "Cannot handle sample moves for cross study submission #{submission.id}" if submission.orders.size > 1
        puts "MULTI ORDER >>>>>>>>>>>>>>>>>>>>>>>>" if submission.orders.size > 1

        # For each request in the submission we need to determine what the study ID should be.  In
        # the case where the target asset has only one aliquot then it is the study ID of that
        # aliquot.  Where the target asset has many, or the source asset has many, then it is nil.
        puts "\tAdjusting requests to the correct study ID"
        submission.requests.find_each do |request|
          puts "#{request.id}"
          if request.target_asset.present? and request.target_asset.aliquots.size == 1
            request.initial_study_id = request.target_asset.primary_aliquot.study_id
            request.save(validate:false)
          elsif request.asset.nil?
            puts "\t\tNo assets associated with request: #{request.id} state: #{request.state}"
          else
            aliquot_study_ids = request.asset.aliquots.map(&:study_id).uniq
            if aliquot_study_ids.size > 1
              request.initial_study_id = nil
              request.save!
            elsif aliquot_study_ids != [ request.initial_study_id ]
              request.initial_study_id = aliquot_study_ids.first
              request.save!
            end
          end

          puts "\t\tRequest #{request.id}: #{request.asset.try(:sti_type)||'empty'}(#{request.asset_id})--#{request.initial_study_id.inspect}-->#{request.target_asset.try(:sti_type)||'empty'}(#{request.target_asset_id})"
        end

        # Now that all of the requests have been updated we can determine whether this submission
        # is now cross study by looking at the requests for the originally submitted assets.  If
        # they each have a different study ID then we know we need to deal with that.
        order            = submission.order
        initial_requests = submission.requests.for_asset_id(order.assets.map(&:id))
        #raise RuntimeError, "Submission #{submission.id} has no requests leading from submitted assets #{order.submitted_assets.map(&:id).inspect}" if initial_requests.empty?
        if initial_requests.empty?
          puts "#{submission.id} has no requests leading from submitted assets"
          order.study_id = study_to_move_samples_to
          submission.save(validate:false)
          order.save(validate:false)
        else
          study_requests   = initial_requests.group_by(&:initial_study_id)
          raise RuntimeError, "Submission #{submission.id} has no requests!" if study_requests.empty?
          if study_requests.size == 1
            puts "\tSubmission #{submission.id} looks like single study: #{study_requests.keys.inspect}"
            order.study_id = study_requests.keys.first
            submission.save(validate:false)
            order.save(validate:false)
            next
          end
      

          puts "\tSubmision #{submission.id} looks like cross-study: #{study_requests.keys.inspect}"
          # puts "\n#{study_requests.inspect}"

          # Duplicate the order so that we can take it's details and then update the study and
          # the assets that were part of the order.  Obviously this will duplicate the original
          # order but we can live with that for the moment as it's easier to do this than to
          # work out the submitted asset modifications for the original order.
          study_requests.each do |study_id, requests|
            submitted_assets, study_order = requests.map(&:asset).uniq, order.clone
            study_order.study_id = study_id
            # study_order.save_after_unmarshalling
            # <= overcomes project validation code


            study_order.submitted_assets.clear
            submitted_assets.each { |asset| study_order.submitted_assets.create!(:asset => asset) }
          end

          submission.save(validate:false)

          # Destroy the original order
          order.submitted_assets.clear
          order.destroy

          submission.orders.each do |order|
            puts "\t\tOrder #{order.id} from study #{order.study_id}: #{order.assets(true).map(&:id).inspect}"
          end
        end
        c -=1
      end
    end
    raise "Hell... test mode" unless mode == 'run'
  end
end

# move_samples(samples,study_to_move_samples_from,study_to_move_samples_to,user_login,rt_ticket,mode)

