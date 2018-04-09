defmodule MastaniServerWeb.Schema.CMS.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M

  object :cms_queries do
    @desc "get one post"
    field :post, non_null(:post) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.CMS.post/3)
    end

    @desc "get all posts"
    field :posts, non_null(list_of(non_null(:post))) do
      # case error when refresh the schema
      # arg(:filter, :article_filter, default_value: %{first: 20})
      middleware(M.SizeChecker)
      resolve(&Resolvers.CMS.posts/3)
    end

    field :paged_posts, non_null(:paged_posts) do
      arg(:filter, non_null(:paged_article_filter))
      middleware(M.SizeChecker)
      resolve(&Resolvers.CMS.posts/3)
      middleware(M.FormatPagination)
    end

    field :favorite_users, non_null(list_of(non_null(:paged_users))) do
      arg(:id, non_null(:id))
      arg(:type, :cms_part, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      arg(:filter, :paged_article_filter)

      middleware(M.SizeChecker)
      resolve(&Resolvers.CMS.reaction_users/3)
      middleware(M.FormatPagination)
    end

    field :tags, non_null(list_of(non_null(:tag))) do
      arg(:community, non_null(:string))
      arg(:part, non_null(:community_part_enum))
      resolve(&Resolvers.CMS.get_tags/3)
    end
  end
end
