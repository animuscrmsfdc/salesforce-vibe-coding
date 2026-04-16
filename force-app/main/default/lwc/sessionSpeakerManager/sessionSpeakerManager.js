import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import searchSessions from '@salesforce/apex/SessionSpeakerManagerController.searchSessions';
import searchSpeakers from '@salesforce/apex/SessionSpeakerManagerController.searchSpeakers';
import getSessionSpeakers from '@salesforce/apex/SessionSpeakerManagerController.getSessionSpeakers';
import getSessionSpeakersLive from '@salesforce/apex/SessionSpeakerManagerController.getSessionSpeakersLive';
import saveSession from '@salesforce/apex/SessionSpeakerManagerController.saveSession';
import saveSpeaker from '@salesforce/apex/SessionSpeakerManagerController.saveSpeaker';
import saveSessionSpeaker from '@salesforce/apex/SessionSpeakerManagerController.saveSessionSpeaker';
import removeSessionSpeaker from '@salesforce/apex/SessionSpeakerManagerController.removeSessionSpeaker';

// Deterministic avatar color from speaker name
const AVATAR_COLORS = [
    '#1B3A6B', '#4A90D9', '#217346', '#9B59B6',
    '#E67E22', '#C0392B', '#1ABC9C', '#2C3E50'
];

function avatarColor(str) {
    if (!str) return AVATAR_COLORS[0];
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        // eslint-disable-next-line no-bitwise
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function initials(firstName, lastName) {
    return ((firstName || '').charAt(0) + (lastName || '').charAt(0)).toUpperCase() || '?';
}

function formatDateTime(dt) {
    if (!dt) return '—';
    return new Date(dt).toLocaleString(undefined, {
        year: 'numeric', month: 'short', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
    });
}

function enrichSession(session, selectedId) {
    const isSelected = session.Id === selectedId;
    const status = session.Status__c || 'Draft';
    const statusMap = {
        Draft: 'ssm-badge ssm-badge--draft',
        Published: 'ssm-badge ssm-badge--published',
        Cancelled: 'ssm-badge ssm-badge--cancelled'
    };
    return {
        ...session,
        formattedDate: formatDateTime(session.Session_Date__c),
        statusBadgeClass: statusMap[status] || 'ssm-badge',
        isSelected,
        cardClass: isSelected
            ? 'ssm-session-card ssm-session-card--selected'
            : 'ssm-session-card'
    };
}

function enrichSessionSpeaker(ss) {
    const fn = (ss.Speaker__r && ss.Speaker__r.First_Name__c) || '';
    const ln = (ss.Speaker__r && ss.Speaker__r.Last_Name__c) || '';
    return {
        ...ss,
        initials: initials(fn, ln),
        avatarStyle: `background: ${avatarColor(ln + fn)};`
    };
}

function enrichSpeaker(spk) {
    const fn = spk.First_Name__c || '';
    const ln = spk.Last_Name__c || '';
    return {
        ...spk,
        initials: initials(fn, ln),
        avatarStyle: `background: ${avatarColor(ln + fn)};`
    };
}

export default class SessionSpeakerManager extends NavigationMixin(LightningElement) {

    // ─── Step State ──────────────────────────────────────────────────────────
    currentStep = 1;

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }

    get stepPill1Class() {
        return this.currentStep >= 1
            ? 'ssm-step-pill ssm-step-pill--active'
            : 'ssm-step-pill';
    }
    get stepPill2Class() {
        return this.currentStep >= 2
            ? 'ssm-step-pill ssm-step-pill--active'
            : 'ssm-step-pill';
    }
    get stepPill3Class() {
        return this.currentStep >= 3
            ? 'ssm-step-pill ssm-step-pill--active'
            : 'ssm-step-pill';
    }

    // ─── Step 1: Session Search ───────────────────────────────────────────────
    sessionSearchTerm = null;
    selectedSessionId = null;
    @track selectedSession = null;
    showNewSession = false;
    @track newSession = { Status__c: 'Draft', Level__c: '' };
    isSaving = false;
    _sessionSearchTimeout;

    @wire(searchSessions, { searchTerm: '$sessionSearchTerm' })
    _rawSessions;

    get sessions() {
        if (this.sessionSearchTerm === null) return { data: null, error: null };
        if (!this._rawSessions) return { data: null, error: null };
        if (this._rawSessions.error) return this._rawSessions;
        if (!this._rawSessions.data) return this._rawSessions;
        return {
            data: this._rawSessions.data.map(s => enrichSession(s, this.selectedSessionId)),
            error: undefined
        };
    }

    get hasSearched() {
        return this.sessionSearchTerm !== null;
    }

    get hasSessions() {
        return this.sessions.data && this.sessions.data.length > 0;
    }

    get noSessionSelected() {
        return !this.selectedSessionId;
    }

    get newSessionToggleIcon() {
        return this.showNewSession ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get statusOptions() {
        return [
            { label: 'Draft', value: 'Draft' },
            { label: 'Published', value: 'Published' },
            { label: 'Cancelled', value: 'Cancelled' }
        ];
    }

    get levelOptions() {
        return [
            { label: '— None —', value: '' },
            { label: 'Beginner', value: 'Beginner' },
            { label: 'Intermediate', value: 'Intermediate' },
            { label: 'Advanced', value: 'Advanced' }
        ];
    }

    handleSessionSearchChange(event) {
        window.clearTimeout(this._sessionSearchTimeout);
        const val = event.target.value || '';
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._sessionSearchTimeout = setTimeout(() => {
            // Only fire wire when 3+ chars; null suppresses the wire via getter guard
            this.sessionSearchTerm = val.length >= 3 ? val : null;
        }, 300);
    }

    handleSessionSelect(event) {
        const id = event.currentTarget.dataset.id;
        if (this.selectedSessionId === id) {
            this.selectedSessionId = null;
            this.selectedSession = null;
        } else {
            this.selectedSessionId = id;
            const raw = (this._rawSessions.data || []).find(s => s.Id === id);
            this.selectedSession = raw ? enrichSession(raw, id) : null;
        }
    }

    toggleNewSession() {
        this.showNewSession = !this.showNewSession;
    }

    handleNewSessionFieldChange(event) {
        const field = event.target.name;
        const value = event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;
        this.newSession = { ...this.newSession, [field]: value };
    }

    async handleSaveNewSession() {
        if (!this.newSession.Session_Date__c) {
            this._toast('Session Date is required', 'Please enter a session date before saving.', 'error');
            return;
        }
        this.isSaving = true;
        try {
            const saved = await saveSession({ session: this.newSession });
            this._toast('Session created', `"${saved.Name}" has been created.`, 'success');
            this.selectedSessionId = saved.Id;
            this.selectedSession = enrichSession(saved, saved.Id);
            this.showNewSession = false;
            this.newSession = { Status__c: 'Draft', Level__c: '' };
            await refreshApex(this._rawSessions);
        } catch (e) {
            this._toast('Error saving session', this._errorMessage(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async goToStep2() {
        if (!this.selectedSessionId) {
            this._toast('No session selected', 'Please select or create a session before proceeding.', 'warning');
            return;
        }
        this.currentStep = 2;
        // Imperative fetch as fallback in case the wire channel drops in Local Dev
        try {
            const data = await getSessionSpeakersLive({ sessionId: this.selectedSessionId });
            this._enrichedSessionSpeakers = {
                data: data.map(enrichSessionSpeaker),
                error: undefined
            };
        } catch (e) {
            // Wire result will handle it if it arrives; ignore imperative error silently
        }
    }

    // ─── Step 2: Speakers ─────────────────────────────────────────────────────
    speakerSearchTerm = null;
    showAddSpeakerPanel = false;
    showNewSpeaker = false;
    @track newSpeaker = {};
    @track pendingSpeaker = null;
    @track pendingAssignment = { Role__c: 'Panelist', Order__c: null, Confirmed__c: false };
    _speakerSearchTimeout;
    _sessionSpeakersResult;
    _enrichedSessionSpeakers = { data: null, error: null };

    @wire(getSessionSpeakers, { sessionId: '$selectedSessionId' })
    wiredSessionSpeakers(result) {
        this._sessionSpeakersResult = result;
        // Only update on success — a wire error must never wipe data loaded by
        // the imperative bootstrap (getSessionSpeakersLive) in goToStep2()
        if (result.data) {
            this._enrichedSessionSpeakers = {
                data: result.data.map(enrichSessionSpeaker),
                error: undefined
            };
        }
    }

    get sessionSpeakers() {
        return this._enrichedSessionSpeakers;
    }

    get hasAssignedSpeakers() {
        return this.sessionSpeakers.data && this.sessionSpeakers.data.length > 0;
    }

    get isSessionCancelled() {
        return this.selectedSession && this.selectedSession.Status__c === 'Cancelled';
    }

    @wire(searchSpeakers, { searchTerm: '$speakerSearchTerm' })
    _rawSpeakers;

    get speakers() {
        if (this.speakerSearchTerm === null) return { data: null, error: null };
        if (!this._rawSpeakers) return { data: null, error: null };
        if (this._rawSpeakers.error) return this._rawSpeakers;
        if (!this._rawSpeakers.data) return this._rawSpeakers;
        return {
            data: this._rawSpeakers.data.map(enrichSpeaker),
            error: undefined
        };
    }

    get hasSpeakers() {
        return this.speakers.data && this.speakers.data.length > 0;
    }

    get newSpeakerToggleIcon() {
        return this.showNewSpeaker ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get roleOptions() {
        return [
            { label: 'Keynote', value: 'Keynote' },
            { label: 'Panelist', value: 'Panelist' },
            { label: 'Moderator', value: 'Moderator' },
            { label: 'Workshop Leader', value: 'Workshop Leader' }
        ];
    }

    get reviewSpeakerCount() {
        return this.sessionSpeakers.data ? this.sessionSpeakers.data.length : 0;
    }

    handleSpeakerSearchChange(event) {
        window.clearTimeout(this._speakerSearchTimeout);
        const val = event.target.value || '';
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._speakerSearchTimeout = setTimeout(() => {
            this.speakerSearchTerm = val.length >= 3 ? val : null;
        }, 300);
    }

    openAddSpeakerPanel() {
        if (this.isSessionCancelled) return;
        this.showAddSpeakerPanel = true;
        this.pendingSpeaker = null;
        this.pendingAssignment = { Role__c: 'Panelist', Order__c: null, Confirmed__c: false };
        this.showNewSpeaker = false;
        this.newSpeaker = {};
    }

    closeAddSpeakerPanel() {
        this.showAddSpeakerPanel = false;
        this.pendingSpeaker = null;
    }

    toggleNewSpeaker() {
        this.showNewSpeaker = !this.showNewSpeaker;
    }

    handleSpeakerPick(event) {
        const id = event.currentTarget.dataset.id;
        const fn = event.currentTarget.dataset.firstname || '';
        const ln = event.currentTarget.dataset.lastname || '';
        const email = event.currentTarget.dataset.email || '';
        this.pendingSpeaker = {
            Id: id,
            First_Name__c: fn,
            Last_Name__c: ln,
            Email__c: email,
            fullName: `${fn} ${ln}`.trim(),
            initials: initials(fn, ln),
            avatarStyle: `background: ${avatarColor(ln + fn)};`
        };
    }

    clearPendingSpeaker() {
        this.pendingSpeaker = null;
    }

    handleNewSpeakerFieldChange(event) {
        const field = event.target.name;
        this.newSpeaker = { ...this.newSpeaker, [field]: event.target.value };
    }

    async handleSaveNewSpeaker() {
        if (!this.newSpeaker.Last_Name__c) {
            this._toast('Last Name required', 'Speaker Last Name is required.', 'error');
            return;
        }
        this.isSaving = true;
        try {
            const saved = await saveSpeaker({ speaker: this.newSpeaker });
            this._toast('Speaker created', `${saved.First_Name__c || ''} ${saved.Last_Name__c} has been created.`, 'success');
            const fn = saved.First_Name__c || '';
            const ln = saved.Last_Name__c || '';
            this.pendingSpeaker = {
                Id: saved.Id,
                First_Name__c: fn,
                Last_Name__c: ln,
                Email__c: saved.Email__c,
                fullName: `${fn} ${ln}`.trim(),
                initials: initials(fn, ln),
                avatarStyle: `background: ${avatarColor(ln + fn)};`
            };
            this.showNewSpeaker = false;
            this.newSpeaker = {};
            // Reset search term to re-trigger the wire on next keystroke
            this.speakerSearchTerm = null;
        } catch (e) {
            this._toast('Error saving speaker', this._errorMessage(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleAssignmentRoleChange(event) {
        this.pendingAssignment = { ...this.pendingAssignment, Role__c: event.detail.value };
    }

    handleAssignmentOrderChange(event) {
        this.pendingAssignment = { ...this.pendingAssignment, Order__c: event.target.value };
    }

    handleAssignmentConfirmedChange(event) {
        this.pendingAssignment = { ...this.pendingAssignment, Confirmed__c: event.target.checked };
    }

    async handleAddSpeakerToSession() {
        if (!this.pendingSpeaker || !this.selectedSessionId) return;
        this.isSaving = true;
        try {
            await saveSessionSpeaker({
                ss: {
                    Session__c: this.selectedSessionId,
                    Speaker__c: this.pendingSpeaker.Id,
                    Role__c: this.pendingAssignment.Role__c,
                    Order__c: this.pendingAssignment.Order__c,
                    Confirmed__c: this.pendingAssignment.Confirmed__c
                }
            });
            this._toast('Speaker added', `${this.pendingSpeaker.fullName} has been added to the session.`, 'success');
            this.closeAddSpeakerPanel();
            await this._refreshSpeakers();
        } catch (e) {
            this._toast('Error adding speaker', this._errorMessage(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async handleRemoveSpeaker(event) {
        const ssId = event.currentTarget.dataset.id;
        try {
            await removeSessionSpeaker({ sessionSpeakerId: ssId });
            this._toast('Speaker removed', 'Speaker has been removed from this session.', 'success');
            await this._refreshSpeakers();
        } catch (e) {
            this._toast('Error removing speaker', this._errorMessage(e), 'error');
        }
    }

    async handleConfirmedToggle(event) {
        const ssId = event.currentTarget.dataset.id;
        const confirmed = event.target.checked;
        const existing = (this._sessionSpeakersResult.data || []).find(ss => ss.Id === ssId);
        if (!existing) return;
        try {
            await saveSessionSpeaker({
                ss: {
                    Id: ssId,
                    Session__c: existing.Session__c,
                    Speaker__c: existing.Speaker__c,
                    Role__c: existing.Role__c,
                    Order__c: existing.Order__c,
                    Confirmed__c: confirmed
                }
            });
            await this._refreshSpeakers();
        } catch (e) {
            this._toast('Error updating confirmation', this._errorMessage(e), 'error');
        }
    }

    async _refreshSpeakers() {
        const data = await getSessionSpeakersLive({ sessionId: this.selectedSessionId });
        this._enrichedSessionSpeakers = {
            data: data.map(enrichSessionSpeaker),
            error: undefined
        };
    }

    goToStep1() { this.currentStep = 1; }
    goToStep3() { this.currentStep = 3; }

    // ─── Step 3: Review & Navigation ─────────────────────────────────────────
    navigateToSession() {
        if (!this.selectedSessionId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedSessionId,
                objectApiName: 'Session__c',
                actionName: 'view'
            }
        });
    }

    handleReset() {
        this.currentStep = 1;
        this.sessionSearchTerm = null;
        this.selectedSessionId = null;
        this.selectedSession = null;
        this.showNewSession = false;
        this.newSession = { Status__c: 'Draft', Level__c: '' };
        this.speakerSearchTerm = null;
        this.showAddSpeakerPanel = false;
        this.pendingSpeaker = null;
        this.pendingAssignment = { Role__c: 'Panelist', Order__c: null, Confirmed__c: false };
        this._enrichedSessionSpeakers = { data: null, error: null };
    }

    // ─── Utilities ────────────────────────────────────────────────────────────
    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _errorMessage(error) {
        if (!error) return 'An unexpected error occurred.';
        if (error.body) {
            if (error.body.message) return error.body.message;
            if (error.body.output) {
                const errs = error.body.output.errors;
                if (errs && errs.length > 0) return errs[0].message;
                const fieldErrs = error.body.output.fieldErrors;
                if (fieldErrs) {
                    const flat = Object.values(fieldErrs).flat();
                    if (flat.length > 0) return flat[0].message;
                }
            }
            if (error.body.fieldErrors) {
                const flat = Object.values(error.body.fieldErrors).flat();
                if (flat.length > 0) return flat[0].message;
            }
        }
        if (error.message) return error.message;
        return 'An unexpected error occurred.';
    }
}
