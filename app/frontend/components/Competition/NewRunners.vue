<template>
    <div class="mt-4">
        <a :href="`/competitions/${competitionId}`" class="btn btn-success btn-sm">Competitia</a>
        <a :href="`/memberships?from_competition_id=${competitionId}`" class="btn btn-success btn-sm">Categorii</a>

        <table class="table table-striped table-bordered table-hover mt-3" id="runners-table">
            <thead class="table-primary">
                <tr>
                    <th scope="col">FOS ID</th>
                    <th>Nume</th>
                    <th>Genul</th>
                    <th>An Nastere</th>
                    <th>Club</th>
                    <th>Alt Sportiv</th>
                    <th>Uneste</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="runner in runners" :key="runner.id">
                    <td>{{ runner.id }}</td>
                    <td>{{ runner.runner_name }} {{ runner.surname }}</td>
                    <td>{{ runner.gender }}</td>
                    <td>{{ runner.yob }}</td>
                    <td>
                        <a v-if="runner.club" :href="`/clubs/${runner.club.id}`">{{ runner.club.club_name }}</a>
                    </td>
                    <td>
                        <select class="form-select form-select-sm" v-model="mergeTargets[runner.id]">
                            <option :value="null">--</option>
                            <option v-for="r in otherRunners(runner.id)" :key="r.id" :value="r.id">
                                {{ r.runner_name }} {{ r.surname }}
                            </option>
                        </select>
                    </td>
                    <td>
                        <button v-if="isAdmin" class="btn btn-sm btn-success" :disabled="!mergeTargets[runner.id]" @click="openMergeModal(runner)">
                            Uneste
                        </button>
                    </td>
                </tr>
            </tbody>
        </table>

        <MergeModal ref="mergeModal" @save="handleMergeSave" />
    </div>
</template>
<script setup>
import { ref, reactive, onMounted } from 'vue'
import axios from '@/axios'
import MergeModal from '../Runner/MergeModal.vue'
import { isAdmin } from '@/currentUser'

const competitionId = ref("")
const runners = ref([])
const allRunners = ref([])
const mergeTargets = reactive({})
const mergeModal = ref(null)

onMounted(() => {
    competitionId.value = window.location.pathname.split('/')[2]
    getData()
})

async function getData() {
    const res = await axios.get(`/competitions/${competitionId.value}/new_runners.json`)
    runners.value = res.data.runners
    allRunners.value = res.data.all_runners
    runners.value.forEach(r => { mergeTargets[r.id] = null })
}

function otherRunners(id) {
    return allRunners.value.filter(r => r.id !== id)
}

function openMergeModal(runner) {
    const targetId = mergeTargets[runner.id]
    if (!targetId) return

    const selected = allRunners.value.find(r => r.id === targetId)
    mergeModal.value.show(selected, runner)
}

async function handleMergeSave(payload) {
    const attributes = {}
    Object.entries(payload.selections).forEach(([ key, source ]) => {
        if (source === 'merged') {
            attributes[key] = payload.mergedRunner[key]
        } else if (source === 'other') {
            attributes[key] = payload.otherValues[key]
        }
    })

    const body = { merged_runner_id: payload.mergedRunner.id }
    if (Object.keys(attributes).length > 0) {
        body.runner = attributes
    }

    await axios.post(`/runners/${payload.mainRunner.id}/merge_runners`, body)

    window.location.reload()
}
</script>
