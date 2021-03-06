# encoding: UTF-8
require_relative '../test_helper'
require_relative '../adnetwork_definitions'

class KafkaEventConversionTest < Minitest::Test

  def setup
    payload = EventPayloads.conversion
    @event = Consumers::Kafka::ConversionEvent.new(payload)
    NetworkUser.delete_all
    Postback.delete_all
  end

  context "use postback cache" do
    should "use it correctly" do
      c = {
        "mac_network" => {
          "mac" => {
            2 => {
              "ios" => [1,2,3,4],
              "all" => [5,6,7,8]
            }
          }
        }
      }
      assert_equal [1,2,3,4,5,6,7,8], @event.postbacks(c).sort
    end
  end

  context "basics" do
    should "have click and install events" do
      assert_kind_of Consumers::Kafka::InstallEvent, @event.install
      assert_kind_of Consumers::Kafka::ClickEvent, @event.click
    end

    should "have idfas" do
      assert_equal "ECC27E57-1605-2714-CAFE-13DC6DFB742F", @event.install.idfa
      assert_equal @event.install.idfa, @event.click.idfa
      assert_equal @event.idfa, @event.click.idfa
    end

    should "generate urls" do
      base_data = {
        :network => "mac_network",
        :event   => @event.call,
        :user_id => @event.user_id,
        :env     => {
          "netcfg" => {
            "aid" => "AidDemo",
            "pkg" => "PackageNameDemo",
          }
        }
      }

      pbs = [
             # don't select this since the platform doesn't match
             { :platform      => "dontselect",
             },
             # select this since the platform is 'all'
             { :platform      => "all",
             },
             # select this since the platform is the same as the event
             { :platform      => "ios",
             },
             # don't use this because it requires a user.
             { :platform      => "all",
               :user_required => true
             }
            ].map { |overrides| generate_postback(overrides.merge(base_data)) }

      assert_equal 3, @event.postbacks.count
      assert_equal 2, @event.generate_urls.count
      assert_equal([{:url=>"https://localhost.com/convALL?adid="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&aid=AidDemo&"+
                      "did=clickdata&pkg=PackageNameDemo",
                      :body=>"", :header=>{}, :pbid => pbs[1].id},
                    {:url=>"https://localhost.com/conv?adid="+
                      "ECC27E57-1605-2714-CAFE-13DC6DFB742F&aid=AidDemo&"+
                      "did=clickdata&pkg=PackageNameDemo",
                      :body=>"", :header=>{}, :pbid => pbs[2].id}],
                   @event.generate_urls.sort_by { |h| h[:pbid] })
    end
  end
end
