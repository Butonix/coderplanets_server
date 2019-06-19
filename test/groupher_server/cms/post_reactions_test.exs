defmodule GroupherServer.Test.PostReactions do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user community post_attrs)a}
  end

  describe "[cms post star/favorite reaction]" do
    test "star and undo star reaction to post", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, _} = CMS.reaction(:post, :star, post.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:post, :star, post.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      {:ok, _} = CMS.undo_reaction(:post, :star, post.id, user)
      {:ok, reaction_users2} = CMS.reaction_users(:post, :star, post.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end

    test "favorite and undo favorite reaction to post", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      # undo test
      {:ok, _} = CMS.undo_reaction(:post, :favorite, post.id, user)
      {:ok, reaction_users2} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end
end
