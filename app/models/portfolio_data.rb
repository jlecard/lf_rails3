class PortfolioData < ActiveRecord::Base
  self.table_name = "portfolio_datas"
  belongs_to :metadata
end