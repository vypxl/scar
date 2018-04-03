
module Scar
  abstract class System
    def update(app : App, space : Space, dt); end
    def render(app : App, space : Space, dt); end
  end # End class System
end # End module Scar
