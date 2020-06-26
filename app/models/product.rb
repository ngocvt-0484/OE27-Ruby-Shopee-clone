class Product < ApplicationRecord
  PRODUCT_PARAMS = [
      :name, :brand_id, :category_id, :price, :description, :avatar,
      product_colors_attributes: [:id, :product_id, :color_id, :quantity, :_destroy],
      images_attributes: [:id, :image, :_destroy]
  ]

  has_many :product_colors, dependent: :destroy
  has_many :colors, through: :product_colors, dependent: :destroy
  has_many :images, dependent: :destroy
  belongs_to :user
  belongs_to :category
  belongs_to :brand
  has_many :order_items

  accepts_nested_attributes_for :product_colors, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :images, allow_destroy: true, reject_if: :all_blank

  delegate :name, to: :brand, prefix: true
  delegate :name, to: :category, prefix: true

  validates :name, presence: true, uniqueness: true, length: {maximum: Settings.shop.name_max_length}
  validates :brand_id, :category_id, :user_id, presence: true
  validates :price, presence: true, numericality: true
  validates :description, presence: true, length: {maximum: Settings.shop.description_max_length}
  validates :description, presence: true, length: {maximum: Settings.shop.description_max_length}

  before_save :set_slug

  scope :by_created_at, -> {order created_at: :desc}
  scope :select_fields, -> {select :id, :name, :slug, :price, :brand_id, :category_id, :created_at, :deleted_at}
  scope :not_deleted, -> {where deleted_at: nil}
  scope :by_slug, -> (slug) {where slug: slug}
  scope :group_by_month, -> {group("MONTH(orders.created_at)")}
  scope :total_money, -> {sum("order_items.price_product * order_items.quantity")}
  scope :total_product, -> {sum("order_items.quantity")}
  scope :total_order, -> {count("orders.id")}
  scope :this_month, -> {where "MONTH(orders.created_at) = ?", Time.now.strftime("%m")}

  mount_uploader :avatar, ProductImageUploader,
                 reject_if: proc { |param| param[:avatar].blank? &&
                     param[:id].blank? }, allow_destroy: true

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize
  end
end
