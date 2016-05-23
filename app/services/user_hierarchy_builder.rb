class UserHierarchyBuilder
  MissingParentNode = Class.new(RuntimeError)
  attr_reader :root, :existing_email_pairs

  class RootNode
    attr_reader :children

    def initialize
      @children = []
    end

    def add_child(node)
      node.parent = self
      @children << node
    end

    def walk(&block)
      @children.each do |child|
        child.walk(&block)
      end
    end

    def walk_with_level(&block)
      @children.each do |child|
        child.walk_with_level(0, &block)
      end
    end

    def root?
      true
    end
  end

  class Node
    attr_reader :email
    attr_reader :children
    attr_reader :row
    attr_accessor :parent

    def initialize(email:, children: [], row: nil)
      @email = email
      @children = []
      @row = row
    end

    def add_child(node)
      node.parent = self
      @children << node
    end

    def walk(&block)
      block.call(self)
      @children.each do |child|
        child.walk(&block)
      end
    end

    def walk_with_level(level, &block)
      block.call(self, level: level)
      @children.each do |child|
        child.walk_with_level(level + 1, &block)
      end
    end

    def parents
      parent = @parent
      parents = []
      until parent.root?
        parents << parent
        parent = parent.parent
      end
      parents
    end

    def self_and_parents
      parents.unshift(self)
    end

    def existing?
      !row.present?
    end

    def root?
      false
    end
  end

  def initialize(email_pairs = [])
    @existing_email_pairs = email_pairs
    @linked_nodes = {}
    @root = RootNode.new
  end

  def prepare
    self.class.build_top_level(@root, @linked_nodes, existing_email_pairs)
  end

  # This method is called import but it only builds a node and adds it to the parent node
  # and returns the added node.
  def import(manager_email, user_email, row)
    parent_node = manager_email.present? ? @linked_nodes[manager_email] : @root
    return nil unless parent_node

    node = Node.new(email: user_email, row: row)
    @linked_nodes[user_email] = node
    parent_node.add_child(node)
    node
  end

  def walk(&block)
    @root.walk(&block)
  end

  def walk_with_level(&block)
    @root.walk_with_level(&block)
  end

  def self.build_top_level(root, linked_nodes, email_pairs)
    missing_email_pairs = email_pairs.reject do |manager_email, user_email|
      if top_level_node?(manager_email)
        node = Node.new(email: user_email)
        linked_nodes[user_email] = node
        root.add_child(node)
        true
      else
        false
      end
    end

    link_next_level(linked_nodes, missing_email_pairs)
  end

  def self.top_level_node?(managers_email)
    !managers_email.present?
  end

  def self.link_next_level(linked_nodes, email_pairs)
    missing_email_pairs = email_pairs.reject do |manager_email, user_email|
      if manager_node = linked_nodes[manager_email]
        node = Node.new(email: user_email)
        linked_nodes[user_email] = node
        manager_node.add_child(node)
        true
      else
        false
      end
    end

    return if missing_email_pairs.empty?

    if missing_email_pairs == email_pairs
      fail MissingParentNode, "Failed to find any nodes in #{ missing_email_pairs.inspect }"
    else
      link_next_level(linked_nodes, missing_email_pairs)
    end
  end
end
