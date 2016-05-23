require 'spec_helper'

describe UserHierarchyBuilder do
  let (:email_pairs) do
    [
      ["jerry@email.com", "george@email.com"],
      ["larry@email.com", "jerry@email.com"],
      ["larry@email.com", "elaine@email.com"],
      ["cbs@email.com", "larry@email.com"],
      [nil, "cbs@email.com"]
    ]
  end

  context "create the heiracrchy tree" do
    it "imports an array of email addresses [manager, user] and creates the tree" do
      builder = UserHierarchyBuilder.new(email_pairs)
      builder.prepare
      expect(builder.root.children.first.email).to eql("cbs@email.com")
    end

    it 'builds the top level of the heirarchy' do
      linked_nodes = {}
      one_level_email_pairs = [[nil, "cbs@email.com"]]
      UserHierarchyBuilder.build_top_level UserHierarchyBuilder::RootNode.new, linked_nodes, one_level_email_pairs
      expect(linked_nodes.keys).to eql(one_level_email_pairs.map(&:last)) # linked_nodes is mutated within the build_top_level method
    end

    it 'builds two levels of heirarchy' do
      linked_nodes = {}
      two_level_email_pairs = [[nil, "cbs@email.com"], ["cbs@email.com", "larry@email.com"]]
      UserHierarchyBuilder.build_top_level UserHierarchyBuilder::RootNode.new, linked_nodes, two_level_email_pairs
      expect(linked_nodes.keys).to eql(two_level_email_pairs.map(&:last))
    end

    it 'builds three levels of heirarchy' do
      linked_nodes = {}
      three_level_email_pairs = [[nil, "cbs@email.com"], ["cbs@email.com", "larry@email.com"], ["larry@email.com", "elaine@email.com"]]
      UserHierarchyBuilder.build_top_level UserHierarchyBuilder::RootNode.new, linked_nodes, three_level_email_pairs
      expect(linked_nodes.keys).to eql(three_level_email_pairs.map(&:last))
    end

    it 'returns MissingParentNode error if an email pair missing a parent (manager) is passed in' do
      linked_nodes = {}
      missing_manager_email_pair = [["jerry@email.com", "george@email.com"]]
      expect { UserHierarchyBuilder.build_top_level UserHierarchyBuilder::RootNode.new, linked_nodes, missing_manager_email_pair }.to raise_error(UserHierarchyBuilder::MissingParentNode)
    end

  end
end
