class Script < ActiveRecord::Base
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'
  has_many :logs
  has_many :attachments, :dependent => :destroy

  before_create :generate_guid

  validates :name, presence: true

  def generate_guid
    uuid = SecureRandom.uuid.split('-').first
    uuid << Time.now.strftime("%Y%m%d%H%M%S%L") unless Script.where(guid: uuid).first.nil?
    self.guid = uuid
  end

  def creater_name
    return nil unless created_by
    created_by.name
  end

  def updater_name
    return nil unless updated_by
    updated_by.name
  end

  def formatted_created_at
    return self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at
    ''
  end

  def formatted_updated_at
    return self.updated_at.strftime("%Y-%m-%d %H:%M:%S") if self.updated_at
    ''
  end

  def remote_script(root_url)
    [
      "curl #{root_url}scripts/#{guid}.sh | sh > sunline.log 2>&1",
       "curl #{root_url}scripts/#{guid}/log.json -X POST -F host=`hostname` -F log_file=@sunline.log"
    ].join(";")
  end
end
