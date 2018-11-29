# if the samples have been put in the wrong wells (on the sequencer) repoint requests to wells (target_asset)
r1 => w2
r2 => w1
# empty well aliquots and dup asset aliquots to target
w2.aliquots = r1.aliquots.map(&:dup)
w1.aliquots = r2.aliquots.map(&:dup)
# rebroadcast the batch
b.touch; b.save!; b.broadcast