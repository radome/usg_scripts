
class Rebroadcaster
  DEFAULT = [Order, Submission, Request, PlatePurpose, Study, StudySample, Sample, Aliquot, Tag, Project, Asset, AssetLink, WellAttribute, Metadata::Base, Batch, BatchRequest, Role, Role::UserRole, ReferenceGenome, Messenger, BroadcastEvent]
  attr_reader :from, :to
  def initialize(classes,from,to)
    @classes = classes
    @from = from
    @to = to
    @obs = AmqpObserver.instance
  end

  def rebroadcast
    @classes.each do |klass|
      puts "Reboadcast #{klass.name}"
      klass.where('updated_at > ? AND updated_at < ?', from, to).pluck(:id).each do |record_id|
        print "#{record_id},"
        @obs << klass.find(record_id)
      end
    end
  end
end



Rebroadcaster.new(Rebroadcaster::DEFAULT,Date.parse('2016-11-30'),Date.parse('2016-12-09')).rebroadcast
