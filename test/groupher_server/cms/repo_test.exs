defmodule GroupherServer.Test.Repo do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    {:ok, ~m(user community repo_attrs)a}
  end

  describe "[cms repo curd]" do
    alias CMS.{Author, Community}

    test "can create repo with valid attrs", ~m(user community repo_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user)

      assert repo.title == repo_attrs.title
      assert repo.contributors |> length !== 0
    end

    test "created repo has origial community info", ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user)
      {:ok, found} = ORM.find(CMS.Repo, repo.id, preload: :origial_community)

      assert repo.origial_community_id == community.id
      assert found.origial_community.id == community.id
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user community repo_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, _} = CMS.create_content(community, :repo, repo_attrs, user)
      {:ok, author} = ORM.find_by(Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create repo with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_content(ivalid_community, :repo, invalid_attrs, user)
    end
  end
end
