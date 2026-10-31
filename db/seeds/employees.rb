# A fixed roster per company, so re-seeding changes nothing and the assessments seed can
# lean on the same people.
FIRST_NAMES = %w[
  Amara Ben Chloe Daniel Esme Farid Grace Hugo Imani Jonas Keira Liam Maya Noor Oscar
  Priya Quinn Rosa Samir Tessa Umar Vera Will Xiu Yusuf Zara
].freeze

LAST_NAMES = %w[
  Adeyemi Brooks Chen Dlamini Evans Fischer Gupta Howard Ibrahim Jansen Khan Lund
  Mokoena Novak Okafor Petersen Quist Reyes Singh Thorne Usman Varga Walsh Xu Young Zulu
].freeze

Company.find_each do |company|
  domain = "#{company.name.split.first.downcase}.example"

  FIRST_NAMES.each_with_index do |first, i|
    last = LAST_NAMES[i]
    company.employees.find_or_create_by!(email: "#{first}.#{last}@#{domain}".downcase) do |employee|
      employee.name = "#{first} #{last}"
    end
  end
end
