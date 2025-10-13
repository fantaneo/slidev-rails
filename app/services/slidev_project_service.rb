class SlidevProjectService
  PROJECTS_DIR = Rails.root.join('slidev_projects')
  PUBLIC_SLIDES_DIR = Rails.root.join('public', 'slides')

  def initialize
    FileUtils.mkdir_p(PROJECTS_DIR)
    FileUtils.mkdir_p(PUBLIC_SLIDES_DIR)
  end

  def create_project(name)
    project_path = PROJECTS_DIR.join(name)

    # Slidevプロジェクトの初期化
    # "Install and start it now?" のプロンプトに自動的に "no" を応答
    cmd = "cd #{PROJECTS_DIR} && echo 'n' | npm create slidev@latest #{name} -- --template basic --yes"
    success = system(cmd)

    unless success
      raise "Slidevプロジェクト作成に失敗しました。終了コード: #{$?.exitstatus}"
    end

    project_path.to_s
  end

  def build_project(slide)
    project_path = slide.project_path
    output_dir = PUBLIC_SLIDES_DIR.join(slide.slug)

    # Slidevプロジェクトのビルド
    # エラー詳細をキャプチャするため、出力をログファイルに記録
    # Node.jsのヒープメモリを4GBに増やしてメモリ不足エラーを回避
    log_file = Rails.root.join('log', "slidev_build_#{slide.slug}.log")
    cmd = "cd #{project_path} && npm install && NODE_OPTIONS='--max-old-space-size=4096' npm run build -- --base /slides/#{slide.slug}/ --out #{output_dir} > #{log_file} 2>&1"
    success = system(cmd)

    unless success
      # エラー詳細をログから読み取る
      error_message = extract_build_error(log_file, slide.slug)
      raise error_message
    end

    output_dir.to_s
  end

  def delete_project(slide)
    errors = []

    begin
      FileUtils.rm_rf(slide.project_path) if File.exist?(slide.project_path)
    rescue => e
      errors << "プロジェクト削除エラー: #{e.message}"
    end

    begin
      public_path = PUBLIC_SLIDES_DIR.join(slide.slug)
      FileUtils.rm_rf(public_path) if File.exist?(public_path)
    rescue => e
      errors << "ビルド成果物削除エラー: #{e.message}"
    end

    raise errors.join(', ') if errors.any?
  end

  private

  # ビルドログから実際のエラー原因を抽出する
  def extract_build_error(log_file, slug)
    return "Slidevのビルドに失敗しました。ログファイルが見つかりません。" unless File.exist?(log_file)

    log_content = File.read(log_file)
    lines = log_content.lines

    # Viteのビルドエラーを探す
    error_info = extract_vite_error(lines, slug)
    return error_info if error_info

    # その他の一般的なエラーを探す
    error_info = extract_general_error(lines)
    return error_info if error_info

    # エラーが特定できない場合は、ビルド失敗の前後を表示
    "Slidevのビルドに失敗しました。詳細はログファイルを確認してください: log/slidev_build_#{slug}.log"
  end

  # Vite/Vueのコンパイルエラーを抽出
  def extract_vite_error(lines, slug)
    # 「[vite:vue]」や「SyntaxError:」などのパターンを探す
    error_line_index = lines.find_index { |line| line.include?('[vite:vue]') || line.include?('SyntaxError:') }
    return nil unless error_line_index

    # エラーメッセージと関連情報を抽出
    error_lines = []

    # エラーメッセージ本体を取得（通常は最初の行に含まれる）
    if lines[error_line_index].include?('[vite:vue]')
      # [vite:vue] のメッセージからエラー内容を抽出
      error_msg = lines[error_line_index].strip.gsub(/\[vite:vue\]\s*\[plugin vite:vue\]\s*/, '')
      error_lines << error_msg
    elsif lines[error_line_index].include?('SyntaxError:')
      error_msg = lines[error_line_index].strip.gsub(/^SyntaxError:\s*\[plugin vite:vue\]\s*/, '')
      error_lines << error_msg
    end

    # ファイルと位置情報を探す
    file_line = lines.find { |line| line.include?('file:') && line.include?('slides.md') }
    if file_line
      # ファイルパスから実際のファイル名と行番号を抽出
      if file_line =~ /slides\.md__slidev_\d+\.md:(\d+):(\d+)/
        line_num = $1
        col_num = $2
        error_lines << "エラー箇所: slides.md の #{line_num}行目、#{col_num}列目付近"
      elsif file_line =~ /slides\.md:(\d+):(\d+)/
        line_num = $1
        col_num = $2
        error_lines << "エラー箇所: slides.md の #{line_num}行目、#{col_num}列目付近"
      end
    end

    return nil if error_lines.empty?

    # エラーの種類に応じたヒントを追加
    hint = get_error_hint(error_lines.first)
    error_lines << hint if hint

    "Slidevのビルドに失敗しました:\n\n#{error_lines.join("\n")}\n\nslides.mdの構文を確認してください。"
  end

  # 一般的なエラーを抽出
  def extract_general_error(lines)
    # 「Error:」や「ERROR」などのキーワードを含む行を探す
    error_lines = lines.select { |line|
      line =~ /Error:/i || line =~ /ERROR/i || line.include?('failed')
    }.first(5)

    return nil if error_lines.empty?

    "Slidevのビルドに失敗しました:\n\n#{error_lines.join("\n").strip}"
  end

  # エラーメッセージに基づいたヒントを提供
  def get_error_hint(error_message)
    case error_message
    when /Element is missing end tag/i
      "ヒント: HTMLタグが正しく閉じられていません。<div>には</div>が必要です。"
    when /Unexpected token/i
      "ヒント: 構文エラーがあります。Markdown記法やコードブロックの閉じ忘れを確認してください。"
    when /Cannot find module/i
      "ヒント: モジュールが見つかりません。package.jsonの依存関係を確認してください。"
    else
      nil
    end
  end

end
