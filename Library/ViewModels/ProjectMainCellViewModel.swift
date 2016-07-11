import KsApi
import ReactiveCocoa
import Result
import Prelude

public protocol ProjectMainCellViewModelInputs {
  func project(project: Project)
}

public protocol ProjectMainCellViewModelOutputs {
  var projectName: Signal<String, NoError> { get }
  var creatorName: Signal<String, NoError> { get }
  var blurb: Signal<String, NoError> { get }
  var categoryName: Signal<String, NoError> { get }
  var locationName: Signal<String, NoError> { get }
  var backersCount: Signal<String, NoError> { get }
  var pledged: Signal<String, NoError> { get }
  var goal: Signal<String, NoError> { get }
  var stateHidden: Signal<Bool, NoError> { get }
  var stateTitle: Signal<String, NoError> { get }
  var stateMessage: Signal<String, NoError> { get }
  var stateColor: Signal<UIColor, NoError> { get }
  var projectImageURL: Signal<NSURL?, NoError> { get }
  var progress: Signal<Float, NoError> { get }
  var progressHidden: Signal<Bool, NoError> { get }
}

public protocol ProjectMainCellViewModelType {
  var inputs: ProjectMainCellViewModelInputs { get }
  var outputs: ProjectMainCellViewModelOutputs { get }
}

public final class ProjectMainCellViewModel: ProjectMainCellViewModelType, ProjectMainCellViewModelInputs,
ProjectMainCellViewModelOutputs {

  private let projectProperty = MutableProperty<Project?>(nil)
  public func project(project: Project) {
    self.projectProperty.value = project
  }

  public let projectName: Signal<String, NoError>
  public let creatorName: Signal<String, NoError>
  public let blurb: Signal<String, NoError>
  public let categoryName: Signal<String, NoError>
  public let locationName: Signal<String, NoError>
  public let backersCount: Signal<String, NoError>
  public let pledged: Signal<String, NoError>
  public let goal: Signal<String, NoError>
  public let stateHidden: Signal<Bool, NoError>
  public let stateTitle: Signal<String, NoError>
  public let stateMessage: Signal<String, NoError>
  public let stateColor: Signal<UIColor, NoError>
  public let projectImageURL: Signal<NSURL?, NoError>
  public let progress: Signal<Float, NoError>
  public let progressHidden: Signal<Bool, NoError>

  public var inputs: ProjectMainCellViewModelInputs { return self }
  public var outputs: ProjectMainCellViewModelOutputs { return self }

  public init() {
    let project = self.projectProperty.signal.ignoreNil()
    let state = project.map { $0.state }.skipRepeats()

    self.projectName = project.map { $0.name }.skipRepeats()

    self.creatorName = project.map { $0.creator.name }.skipRepeats()

    self.blurb = project.map { $0.blurb }.skipRepeats()

    self.categoryName = project.map { $0.category.name }.skipRepeats()

    self.locationName = project.map { $0.location.displayableName }.skipRepeats()

    self.backersCount = project.map { Format.wholeNumber($0.stats.backersCount) }.skipRepeats()

    self.pledged = project.map { Format.currency($0.stats.pledged, country: $0.country) }.skipRepeats()

    self.goal = project.map {
      Strings.discovery_baseball_card_stats_pledged_of_goal(
        goal: Format.currency($0.stats.goal, country: $0.country)
        )
    }.skipRepeats()

    self.stateTitle = state.map(bannerTitleFor(state:))
      .map { $0 ?? "" }
      .skipRepeats()

    self.stateMessage = project.map(bannerMessageFor(project:))
      .map { $0 ?? "" }
      .skipRepeats()

    self.stateHidden = combineLatest(self.stateTitle, self.stateMessage)
      .map { title, message in title.characters.isEmpty || message.characters.isEmpty }
      .skipRepeats()

    self.stateColor = state.map(bannerColorFor(state:)).skipRepeats(==)

    self.projectImageURL = project.map { $0.photo.full }
      .skipRepeats(==)
      .map(NSURL.init(string:))

    self.progress = project.map { $0.stats.fundingProgress }
      .map(clamp(0.0, 1.0))
      .skipRepeats()

    self.progressHidden = project.map { $0.state != .live }
  }
}

private func bannerTitleFor(state state: Project.State) -> String? {
  switch state {
  case .canceled:
    return Strings.project_status_funding_canceled()
  case .failed:
    return Strings.project_status_funding_unsuccessful()
  case .successful:
    return Strings.project_status_funded()
  case .suspended:
    return Strings.project_status_funding_suspended()
  case .live, .started, .submitted, .purged:
    return nil
  }
}

private func bannerMessageFor(project project: Project) -> String? {
  let deadline = { Format.date(secondsInUTC: project.dates.deadline, timeStyle: .NoStyle) }

  switch project.state {
  case .canceled:
    return Strings.project_status_funding_project_canceled_by_creator()
  case .failed:
    return Strings.project_status_project_funding_goal_not_reached(deadline: deadline())
  case .successful:
    return Strings.project_status_project_was_successfully_funded_on_deadline(deadline: deadline())
  case .suspended:
    return Strings.project_status_funding_project_suspended()
  case .live, .started, .submitted, .purged:
    return nil
  }
}

private func bannerColorFor(state state: Project.State) -> UIColor {
  switch state {
  case .successful:                           return .ksr_green_300
  case .canceled, .failed, .suspended:        return .ksr_grey_400
  case .live, .started, .submitted, .purged:  return .clearColor()
  }
}
