class StudySample < ActiveRecord::Base ; end

# added sample class as comments are not commentable at present 21/3/2019
class Sample
  include Commentable
end

class Asset
  has_many :submitted_assets
  has_many :orders, :through => :submitted_assets, :as => :asset
end; nil

module Submission::QuotaBehaviour
  def book_quota_available_for_request_types!
    # Do not, whatever happens, mess with quota!
  end
end

def update_fluidigm_plates(fluidigm_plates)
  fluidigm_plates.each do |plate_id|
    puts "Updating Fluidigm plate: #{plate_id}"
    plate = Plate.find_by_id plate_id
    plate.touch; plate.save!
    message = Messenger.find_by(target_id:plate_id)
    message.resend
  end
end

def find_asset_groups(sample_names)
  hash = Hash.new{|hsh,key| hsh[key] = [] }
  sample_names.each do |sample_name|
    sample = Sample.find_by(name: sample_name)
    asset_groups = sample.asset_groups
    if !asset_groups.empty?
      asset_groups.each do |ag|
        hash[ag.name] << sample_name
      end
    end
  end; nil
  return hash
end

def find_whole_and_split_asset_groups(asset_group_sample_hash,sample_names)
  # determine which orders are split if any
  whole_asset_groups=[]
  split_asset_groups_hash = Hash.new{|hsh,key| hsh[key] = [] }
  asset_group_sample_hash.each do |ag_name,samples|
    asset_group = AssetGroup.find_by(name: ag_name)
    order = Order.find_by(asset_group_id: asset_group.id)
    aliquot_count = asset_group.assets.map(&:aliquots).flatten.size
    if  aliquot_count == samples.size
      puts "#{order.study_id} #{order.submission_id} #{order.submission.orders.size} #{ag_name} - #{aliquot_count}/#{samples.size} :: All assets to be moved"
      whole_asset_groups << asset_group
      # sample_move
    else
      puts "#{order.study_id} #{order.submission_id} #{order.submission.orders.size} #{ag_name} - #{aliquot_count}/#{samples.size} :: Not all assets to be moved - split"
      to_remove = sample_names & asset_group.assets.map(&:aliquots).flatten.map(&:sample).map(&:name)
      to_remove.map(&split_asset_groups_hash[asset_group].method(:<<))
    end
  end; nil
  return whole_asset_groups, split_asset_groups_hash
end

def split_asset_groups_and_update(split_asset_groups_hash,user,rt_ticket)
  new_orders =[]
  split_asset_groups_hash.each do |ag,to_remove|
    new_name = ag.name+"_#{rt_ticket}"
    puts "#{ag.name} => #{new_name}"
    ag_new = AssetGroup.create!(name: new_name, user_id: user.id, study: @study_to)
    orders = Order.where(asset_group_id: ag.id).select {|o| o.submission.state == "ready"}
    # assumption is that above will return 1 order with a state of 'ready' if it doesn't then the logic is flawed and we need to bale out
    if orders.size > 1
      raise "More than one order of state READY found... time to tweak the code!"
    else
      assets = ag.assets.select {|a| to_remove.include?(a.aliquots.first.sample.name)}
      
      # remove the assets from the old order
      puts "remove the assets from the old order"
      old_order = orders.first
      old_order.submitted_assets.where(asset: assets).map(&:delete)
      old_order.save(validate:false)
      
      # create new order!
      puts "create new order!"
      new_order = old_order.dup
      new_order.update_attributes!(study: @study_to, user_id: user.id, asset_group_id: ag_new.id, asset_group_name: ag_new.name)
      
      # add the assets to the new order and asset group
      puts "add the assets to the new order and asset group"
      assets.each {|asset| new_order.submitted_assets.create!(:asset => asset)}
      new_order.save!
      new_orders << new_order
      ag.asset_group_assets.where(asset: assets).map(&:delete)
      ag.save!
      ag_new.assets << assets
      ag_new.save!
      puts "old #{ag.name} : #{ag.assets.map(&:aliquots).flatten.size}"
      puts "new #{ag_new.name} : #{ag_new.assets.map(&:aliquots).flatten.size}"
    end
  end
  puts "Created..."
  new_orders.each {|o| puts "#{o.id} :: #{o.asset_group_name}"}
  new_orders.each do |order|
    puts "#{order.id} :: #{order.asset_group.name} - #{order.asset_group.assets.map(&:aliquots).flatten.size}"
    order.requests.each {|request| request.initial_study = @study_to; request.save!}
  end; nil
end

def update_whole_asset_groups(whole_asset_groups)
  whole_asset_groups.each do |asset_group|
    asset_group.update_attributes!(:study => @study_to)
    orders = Order.where(asset_group_id: asset_group.id).select {|o| o.submission.state == "ready"}
    if orders.size > 1
      raise "More than one order of state READY found... time to tweak the code!"
    elsif !orders.empty?
      order = orders.first
      order.requests.each {|request| request.initial_study = @study_to; request.save!}
      order.study = @study_to
      order.save(validate:false)
    end
  end
end

def update_create_requests_on(asset)
  requests = asset.requests.where(request_type_id: [11,143])
  requests.map {|r| r.initial_study = @study_to; r.save!} unless requests.empty?
end

def update_seq_requests(requests)
  requests.each {|r| r.initial_study = @study_to; r.save!}
end

def new_move_samples(sample_names,study_from_id,study_to_id,user_login,rt_ticket,mode)
  ActiveRecord::Base.transaction do 
    fluidigm_plates = []; lane_ids = []; pb_tube_ids = []; movable_classes = ['Well','SampleTube','LibraryTube']
    user = User.find_by_login(user_login) or raise StandardError, "Cannot find the user #{user_login.inspect}"
    @study_to = Study.find(study_to_id)
  
    asset_group_sample_hash = find_asset_groups(sample_names)
    whole_asset_groups, split_asset_groups_hash = find_whole_and_split_asset_groups(asset_group_sample_hash,sample_names)
    update_whole_asset_groups(whole_asset_groups)
    # puts split_asset_groups_hash.inspect
    split_asset_groups_and_update(split_asset_groups_hash,user,rt_ticket)
  
    sample_names.each do |sample_name|
      sample = Sample.find_by_name(sample_name)
      comment_text = "Sample #{sample.id} moved from #{study_from_id} to #{study_to_id} requested via RT ticket #{rt_ticket} using new_sample_move.rb"
      comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Sample move #{rt_ticket}") }

      puts "Moving sample #{sample.id} #{sample.name}"
      [sample].map(&comment_on)
      fluidigm_plates.push(*sample.receptacles.select {|a| a.sti_type == "Well"}.map(&:plate).uniq.compact.select {|p| p.purpose.name.match(/Fluid/)}.map(&:id))
      sample.aliquots.where(study_id: study_from_id).find_each do |aliquot|
        aliquot.study_id = study_to_id
        aliquot.save!
        aliquot.receptacle.tap do |asset|
          if movable_classes.include?(asset.class.name)
            # puts "\tMoving #{asset.sti_type} #{asset.id}"
            update_create_requests_on(asset)
            comment_on.call(asset)
          elsif asset.is_a?(Lane)
            lane_ids << asset.id
          elsif asset.is_a?(PacBioLibraryTube)
            pb_tube_ids << asset.id
        end
        end
      end

      sample.study_samples.find_each do |study_sample|
        begin
          study_sample.update_attributes!(:study_id => study_to_id)
        rescue ActiveRecord::RecordInvalid => invalid
          study_links = StudySample.where(sample_id: study_sample.sample_id, study_id: study_from_id)
          study_links.each do |link|
            puts "Sample already associated with #{study_to_id} => Destroying #{link.inspect}\n"
            link.destroy
          end
        end
      end
      puts "Finished saving study_sample"
    end
    
    if mode == 'test'
      raise "Hell!!!... in test mode"
    else
      if !lane_ids.empty?
        puts "Rebroadcasting batches..."
        lanes = Lane.where(id: lane_ids.uniq)
        update_seq_requests(lanes.map(&:requests_as_target).flatten)
        lanes.map(&:creation_batches).flatten.uniq.each do |batch|
          puts "lane batches: #{batch.id}"
          batch.touch
        end
      end

      if !pb_tube_ids.empty?
        requests = PacBioLibraryTube.where(id: pb_tube_ids.uniq).map(&:requests).flatten
        update_seq_requests(requests)
        requests.map(&:batch).compact.uniq.each do |batch|
          puts "pb batches: #{batch.id}"
          batch.touch
        end
      end

      if !fluidigm_plates.empty?
        puts "Updating\n#{fluidigm_plates.inspect}"
        update_fluidigm_plates(fluidigm_plates.uniq)
      end
    end
  end
end

# new_move_samples(sample_names,study_from_id,study_to_id,user_login,rt_ticket,mode)
