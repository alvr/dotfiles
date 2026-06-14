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
      settings.flavour = "mocha";
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

        settings.keymaps = {
          "<leader>e" = "open";
        };
      };

      lsp = {
        enable = true;

        servers = {
          bashls.enable = true;
          just.enable = true;
          nixd.enable = true;
          tombi.enable = true;
          yamlls.enable = true;
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

        settings.formatters_by_ft = {
          nix = [ "nixfmt" ];
        };
      };

      comment.enable = true;
      dap.enable = true;
      gitsigns.enable = true;
      lsp-lines.enable = true;
      lualine.enable = true;
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
