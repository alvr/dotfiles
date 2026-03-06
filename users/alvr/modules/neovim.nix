{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;

    viAlias = true;
    vimAlias = true;

    globals.mapleader = " ";

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      termguicolors = true;
    };

    colorschemes.catppuccin = {
      enable = true;
      flavour = "mocha";
    };

    plugins = {
      treesitter = {
        enable = true;
        indent.enable = true;
        folding.enable = true;

        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          json
          lua
          make
          markdown
          nix
          regex
          toml
          vim
          vimdoc
          xml
          yaml
        ];
      };

      telescope = {
        enable = true;

        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };
      };

      yazi = {
        enable = true;

        keymaps = {
          "<leader>e" = "open";
        };
      };

      lsp = {
        enable = true;

        servers = {
          # nil_ls.enable = true;
          # lua_ls.enable = true;
          # pyright.enable = true;
          # ts_ls.enable = true;
          # gopls.enable = true;
          # rust_analyzer.enable = true;
          # bashls.enable = true;
        };
      };

      cmp = {
        enable = true;

        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };

      conform-nvim = {
        enable = true;

        formattersByFt = {
          nix = [ "nixfmt" ];
        };
      };

      lualine = {
        enable = true;
        theme = "catppuccin";
      };

      comment.enable = true;
      dap.enable = true;
      gitsigns.enable = true;
      lsp-lines.enable = true;
      luasnip.enable = true;
      notify.enable = true;
      web-devicons.enable = true;
      which-key.enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>w";
        action = ":w<CR>";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = ":q<CR>";
      }
      {
        mode = "n";
        key = "<leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      }
      {
        mode = "n";
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      }
      {
        mode = "n";
        key = "K";
        action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      }
    ];
  };
}
