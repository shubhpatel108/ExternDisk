module ShoesGUI

  def ask_for_default_permission(user=nil)
    win1 = $app.window {}
    @permission_windows.merge!("#{user.username}" => win1) unless user.nil?
    @permission_windows["#{user.username}"].para "Please select view for #{user.username}" unless user.nil?
    files_to_show = files_at_depth("2", "")
    @stk1 = win1.stack {}
    win1.append {
      win1.button "Done" do
        win1.close
        if user.nil?
          write_default_permissions
        else
          write_permissions_for(user)
        end
      end
    }
    @global_stk_hash = {}
    @global_flw_hash = {}
    @global_check = {}
    @permission = {}
    @stk1.append do
      files_to_show.each do |f|
        tokens = f.split("\t")
        @flw1 = @stk1.flow {}
        @global_flw_hash.merge!("#{tokens[0]}" => @flw1)
        @global_flw_hash["#{tokens[0]}"].append do

          chk = @global_flw_hash["#{tokens[0]}"].check
          @global_check.merge!("#{tokens[0]}" => chk)
          @global_check["#{tokens[0]}"].click() do
            if @global_check["#{tokens[0]}"].checked?
              @permission.merge!("#{tokens[0]}" => true)
              @global_check.each do |key,value|
                if key.start_with?("#{tokens[0]}_") then @global_check[key].checked = true end
              end
            else not @global_check["#{tokens[0]}"].checked?
              @permission.merge!("#{tokens[0]}" => false)
              @global_check.each do |key,value|
                if key.start_with?("#{tokens[0]}_") then @global_check[key].checked = false end
              end
            end
          end

          @global_flw_hash["#{tokens[0]}"].para tokens[3]
          if tokens[2]=="true"
            @global_flw_hash["#{tokens[0]}"].button "expand" do
              @global_stk_hash["#{tokens[0]}"].toggle
            end
            @stk2 = @global_flw_hash["#{tokens[0]}"].stack(:hidden => true) {}
            @global_stk_hash.merge!("#{tokens[0]}" => @stk2)
            append_list(tokens[0], (tokens[1].to_i + 1).to_s, tokens[3])
          end
        end
      end
    end
  end

  def append_list(id, depth, path)
    files_to_show = files_at_depth(depth, path)
    @global_stk_hash["#{id}"].append do
      files_to_show.each do |f|
        tokens = f.split("\t")
        @flw1 = @global_stk_hash["#{id}"].flow {}
        @global_flw_hash.merge!("#{tokens[0]}" => @flw1)
        @global_flw_hash["#{tokens[0]}"].append do

          chk = @global_flw_hash["#{tokens[0]}"].check
          @global_check.merge!("#{id}_#{tokens[0]}" => chk)
          @global_check["#{id}_#{tokens[0]}"].click() do
            if @global_check["#{id}_#{tokens[0]}"].checked?
              @permission.merge!("#{tokens[0]}" => true)
              @global_check.each do |key,value|
                if key.start_with?("#{tokens[0]}_") then @global_check[key].checked = true end
                if key.end_with?("_#{id}") then @global_check[key].checked = true end
              end
            else not @global_check["#{id}_#{tokens[0]}"].checked?
              @permission.merge!("#{tokens[0]}" => false)
              @global_check.each do |key,value|
                if key.start_with?("#{tokens[0]}_") then @global_check[key].checked = false end
              end
            end
          end

          @global_flw_hash["#{tokens[0]}"].para tokens[3].gsub(path, "")
          if tokens[2]=="true"
            @global_flw_hash["#{tokens[0]}"].button "expand" do
              @global_stk_hash["#{tokens[0]}"].toggle
            end
            @stk2 = @global_flw_hash["#{tokens[0]}"].stack(:hidden => true) {}
            @global_stk_hash.merge!("#{tokens[0]}" => @stk2)
            append_list(tokens[0], (tokens[1].to_i + 1).to_s, tokens[3])
          end
        end
      end
    end
  end

end